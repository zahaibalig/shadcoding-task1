import requests
import json
from django.conf import settings
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import AllowAny


class VehicleLookupView(APIView):
    """
    GET /api/vehicles/lookup/?registration=<registration_number>

    Proxy endpoint to fetch vehicle data from Statens Vegvesen API.
    Public endpoint - no authentication required.
    """
    permission_classes = [AllowAny]

    def get(self, request):
        # Get registration number from query params
        registration = request.query_params.get('registration', '').strip()

        if not registration:
            return Response(
                {'error': 'Registration number is required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Validate registration format (2-7 characters)
        if len(registration) < 2 or len(registration) > 7:
            return Response(
                {'error': 'Registration number must be between 2 and 7 characters'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Get API key from settings
        api_key = settings.STATENS_VEGVESEN_API_KEY
        if not api_key:
            return Response(
                {'error': 'API key not configured'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

        # Call Statens Vegvesen API
        url = 'https://akfell-datautlevering.atlas.vegvesen.no/enkeltoppslag/kjoretoydata'
        headers = {
            'SVV-Authorization': f'Apikey {api_key}'
        }
        params = {
            'kjennemerke': registration.upper()
        }

        try:
            response = requests.get(url, headers=headers, params=params, timeout=10)

            # Handle different status codes
            if response.status_code == 200:
                data = response.json()

                # DEBUG: Print raw API response
                print("\n" + "="*80)
                print("DEBUG: Raw API Response from Statens Vegvesen")
                print("="*80)
                print(json.dumps(data, indent=2, ensure_ascii=False))
                print("="*80 + "\n")

                # Extract relevant vehicle information
                vehicle_data = self._extract_vehicle_data(data)
                return Response(vehicle_data, status=status.HTTP_200_OK)

            elif response.status_code == 400:
                return Response(
                    {'error': 'Invalid registration number or multiple fields provided'},
                    status=status.HTTP_400_BAD_REQUEST
                )

            elif response.status_code == 403:
                return Response(
                    {'error': 'API key is invalid or expired'},
                    status=status.HTTP_403_FORBIDDEN
                )

            elif response.status_code == 429:
                return Response(
                    {'error': 'Rate limit exceeded. Maximum 50,000 calls per day.'},
                    status=status.HTTP_429_TOO_MANY_REQUESTS
                )

            elif response.status_code == 404:
                # Vehicle not found with the given registration number
                return Response(
                    {'error': 'Please enter a correct registration number. Vehicle not found.'},
                    status=status.HTTP_404_NOT_FOUND
                )

            else:
                # Handle other error responses
                error_message = response.text or 'Unknown error occurred'
                if 'OPPLYSNINGER_IKKE_TILGJENGELIGE' in error_message:
                    return Response(
                        {'error': 'Vehicle information not available'},
                        status=status.HTTP_404_NOT_FOUND
                    )

                return Response(
                    {'error': f'Error from external API: {error_message}'},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )

        except requests.Timeout:
            return Response(
                {'error': 'Request to Statens Vegvesen API timed out'},
                status=status.HTTP_504_GATEWAY_TIMEOUT
            )

        except requests.RequestException as e:
            return Response(
                {'error': f'Failed to connect to Statens Vegvesen API: {str(e)}'},
                status=status.HTTP_503_SERVICE_UNAVAILABLE
            )

    def _extract_vehicle_data(self, data):
        """
        Extract relevant vehicle information from the API response.

        The API returns comprehensive vehicle data. We extract:
        - Brand (merke)
        - Model (modell)
        - Year (årsmodell)
        - Last EU approval date
        - Next EU approval date
        """
        try:
            # Navigate through the nested JSON structure
            # The structure may vary, so we use .get() with defaults
            kjoretoydataListe = data.get('kjoretoydataListe', [])

            if not kjoretoydataListe:
                return {
                    'registration': data.get('kjennemerke', 'N/A'),
                    'brand': 'N/A',
                    'model': 'N/A',
                    'year': 'N/A',
                    'nextEuApproval': 'N/A',
                }

            vehicle_info = kjoretoydataListe[0]

            # DEBUG: Print vehicle_info structure
            print("\n" + "-"*80)
            print("DEBUG: vehicle_info keys:", list(vehicle_info.keys()))
            print("-"*80)

            godkjenning = vehicle_info.get('godkjenning', {})
            tekniskGodkjenning = godkjenning.get('tekniskGodkjenning', {})

            # DEBUG: Print tekniskGodkjenning keys
            print("DEBUG: tekniskGodkjenning keys:", list(tekniskGodkjenning.keys()))

            # DEBUG: Print tekniskeData structure
            tekniske_data = tekniskGodkjenning.get('tekniskeData', {})
            print("DEBUG: tekniskeData keys:", list(tekniske_data.keys()))
            if 'generelt' in tekniske_data:
                print("DEBUG: generelt keys:", list(tekniske_data['generelt'].keys()))
            print("-"*80 + "\n")

            # Extract brand and model
            brand = 'N/A'
            model = 'N/A'
            year = 'N/A'

            # Get generelt data structure
            generelt = tekniske_data.get('generelt', {})

            # Try to get brand from tekniskeData -> generelt -> merke
            if generelt:

                # Extract brand (merke)
                if 'merke' in generelt:
                    merke_data = generelt.get('merke', {})
                    # merke might be a dict or a list
                    if isinstance(merke_data, dict):
                        brand = merke_data.get('merke', 'N/A')
                    elif isinstance(merke_data, list) and len(merke_data) > 0:
                        brand = merke_data[0].get('merke', 'N/A') if isinstance(merke_data[0], dict) else str(merke_data[0])

                # Extract model (handelsbetegnelse)
                if 'handelsbetegnelse' in generelt:
                    model_data = generelt.get('handelsbetegnelse', {})
                    # handelsbetegnelse might be a string, dict, or list
                    if isinstance(model_data, str):
                        model = model_data
                    elif isinstance(model_data, dict):
                        model = model_data.get('handelsbetegnelse', 'N/A')
                    elif isinstance(model_data, list) and len(model_data) > 0:
                        model = model_data[0].get('handelsbetegnelse', 'N/A') if isinstance(model_data[0], dict) else str(model_data[0])

            # Try to get year (årsmodell) from generelt
            if generelt and 'aarsmodell' in generelt:
                year = generelt.get('aarsmodell', 'N/A')

            # Try to get first registration year if årsmodell not available
            if year == 'N/A' and 'forstegangsregistrering' in vehicle_info:
                registrering = vehicle_info.get('forstegangsregistrering', {})
                registrering_dato = registrering.get('registrertForstegangNorgeDato', '')
                if registrering_dato:
                    year = registrering_dato[:4]  # Extract year from date string

            # Extract EU approval date (periodiskKjoretoyKontroll)
            next_eu_approval = 'N/A'

            if 'periodiskKjoretoyKontroll' in vehicle_info:
                pkk = vehicle_info.get('periodiskKjoretoyKontroll', {})

                # Next control due date
                if 'kontrollfrist' in pkk:
                    next_eu_approval = pkk.get('kontrollfrist', 'N/A')

            # Extract registration number
            registration = 'N/A'
            if 'kjennemerke' in vehicle_info:
                kjennemerke = vehicle_info.get('kjennemerke')
                # Handle dict/object format with nested kjennemerke field
                if isinstance(kjennemerke, dict) and 'kjennemerke' in kjennemerke:
                    registration = kjennemerke['kjennemerke']
                # Handle list format
                elif isinstance(kjennemerke, list) and len(kjennemerke) > 0:
                    # List items might be dicts or strings
                    if isinstance(kjennemerke[0], dict) and 'kjennemerke' in kjennemerke[0]:
                        registration = kjennemerke[0]['kjennemerke']
                    else:
                        registration = str(kjennemerke[0])
                # Handle simple string format
                elif isinstance(kjennemerke, str):
                    registration = kjennemerke

            # Fallback to top-level kjennemerke if vehicle_info doesn't have it
            if registration == 'N/A' and 'kjennemerke' in data:
                kjennemerke = data.get('kjennemerke')
                if isinstance(kjennemerke, str):
                    registration = kjennemerke
                elif isinstance(kjennemerke, list) and len(kjennemerke) > 0:
                    registration = str(kjennemerke[0])

            return {
                'registration': registration,
                'brand': brand,
                'model': model,
                'year': str(year),
                'nextEuApproval': next_eu_approval,
            }

        except (KeyError, IndexError, AttributeError) as e:
            # If parsing fails, return N/A for all fields
            return {
                'registration': 'N/A',
                'brand': 'N/A',
                'model': 'N/A',
                'year': 'N/A',
                'nextEuApproval': 'N/A',
                'error': f'Failed to parse vehicle data: {str(e)}'
            }
