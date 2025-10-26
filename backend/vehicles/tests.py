from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APIClient
from rest_framework import status
from unittest.mock import patch, Mock
import requests


class VehicleLookupViewTests(TestCase):
    """
    Comprehensive test suite for VehicleLookupView API endpoint.
    Tests various scenarios including valid/invalid inputs and external API responses.
    """

    def setUp(self):
        """Set up test client and common test data"""
        self.client = APIClient()
        self.url = reverse('vehicle-lookup')  # Assumes URL name is 'vehicle-lookup'
        self.valid_registration = 'AB12345'
        self.api_url = 'https://akfell-datautlevering.atlas.vegvesen.no/enkeltoppslag/kjoretoydata'

        # Sample successful API response
        self.mock_success_response = {
            'kjennemerke': 'AB12345',
            'kjoretoydataListe': [{
                'kjennemerke': {'kjennemerke': 'AB12345'},
                'godkjenning': {
                    'tekniskGodkjenning': {
                        'tekniskeData': {
                            'generelt': {
                                'merke': {'merke': 'Toyota'},
                                'handelsbetegnelse': 'Corolla',
                                'aarsmodell': '2020'
                            }
                        }
                    }
                },
                'periodiskKjoretoyKontroll': {
                    'kontrollfrist': '2025-12-31'
                },
                'forstegangsregistrering': {
                    'registrertForstegangNorgeDato': '2020-01-15'
                }
            }]
        }

    @patch('vehicles.views.settings.STATENS_VEGVESEN_API_KEY', 'test-api-key')
    @patch('vehicles.views.requests.get')
    def test_valid_registration_number_success(self, mock_get):
        """Test successful lookup with valid registration number"""
        # Mock successful API response
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = self.mock_success_response
        mock_get.return_value = mock_response

        # Make request
        response = self.client.get(self.url, {'registration': self.valid_registration})

        # Assertions
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['registration'], 'AB12345')
        self.assertEqual(response.data['brand'], 'Toyota')
        self.assertEqual(response.data['model'], 'Corolla')
        self.assertEqual(response.data['year'], '2020')
        self.assertEqual(response.data['nextEuApproval'], '2025-12-31')

        # Verify API was called correctly
        mock_get.assert_called_once()
        call_args = mock_get.call_args
        self.assertEqual(call_args[0][0], self.api_url)
        self.assertEqual(call_args[1]['params']['kjennemerke'], self.valid_registration.upper())
        self.assertEqual(call_args[1]['headers']['SVV-Authorization'], 'Apikey test-api-key')
        self.assertEqual(call_args[1]['timeout'], 10)

    @patch('vehicles.views.settings.STATENS_VEGVESEN_API_KEY', 'test-api-key')
    @patch('vehicles.views.requests.get')
    def test_invalid_registration_number_404(self, mock_get):
        """Test lookup with non-existent registration number returns proper error"""
        # Mock 404 response from API
        mock_response = Mock()
        mock_response.status_code = 404
        mock_response.text = 'Not found'
        mock_get.return_value = mock_response

        # Make request with valid-length but non-existent registration
        response = self.client.get(self.url, {'registration': 'XX99999'})

        # Assertions
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
        self.assertIn('error', response.data)
        self.assertIn('correct registration number', response.data['error'].lower())

    def test_missing_registration_parameter(self):
        """Test request without registration parameter"""
        response = self.client.get(self.url)

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('error', response.data)
        self.assertEqual(response.data['error'], 'Registration number is required')

    def test_empty_registration_parameter(self):
        """Test request with empty registration parameter"""
        response = self.client.get(self.url, {'registration': '   '})

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('error', response.data)
        self.assertEqual(response.data['error'], 'Registration number is required')

    def test_registration_too_short(self):
        """Test registration number with less than 2 characters"""
        response = self.client.get(self.url, {'registration': 'A'})

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('error', response.data)
        self.assertIn('between 2 and 7 characters', response.data['error'])

    def test_registration_too_long(self):
        """Test registration number with more than 7 characters"""
        response = self.client.get(self.url, {'registration': 'AB123456'})

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('error', response.data)
        self.assertIn('between 2 and 7 characters', response.data['error'])

    @patch('vehicles.views.settings.STATENS_VEGVESEN_API_KEY', 'test-api-key')
    @patch('vehicles.views.requests.get')
    def test_api_400_bad_request(self, mock_get):
        """Test handling of 400 error from external API"""
        mock_response = Mock()
        mock_response.status_code = 400
        mock_get.return_value = mock_response

        response = self.client.get(self.url, {'registration': 'AB12345'})

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('error', response.data)
        self.assertIn('Invalid registration number', response.data['error'])

    @patch('vehicles.views.settings.STATENS_VEGVESEN_API_KEY', 'invalid-key')
    @patch('vehicles.views.requests.get')
    def test_api_403_forbidden(self, mock_get):
        """Test handling of 403 error (invalid API key)"""
        mock_response = Mock()
        mock_response.status_code = 403
        mock_get.return_value = mock_response

        response = self.client.get(self.url, {'registration': 'AB12345'})

        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
        self.assertIn('error', response.data)
        self.assertIn('API key', response.data['error'])

    @patch('vehicles.views.settings.STATENS_VEGVESEN_API_KEY', 'test-api-key')
    @patch('vehicles.views.requests.get')
    def test_api_429_rate_limit(self, mock_get):
        """Test handling of 429 error (rate limit exceeded)"""
        mock_response = Mock()
        mock_response.status_code = 429
        mock_get.return_value = mock_response

        response = self.client.get(self.url, {'registration': 'AB12345'})

        self.assertEqual(response.status_code, status.HTTP_429_TOO_MANY_REQUESTS)
        self.assertIn('error', response.data)
        self.assertIn('Rate limit', response.data['error'])
        self.assertIn('50,000', response.data['error'])

    @patch('vehicles.views.settings.STATENS_VEGVESEN_API_KEY', 'test-api-key')
    @patch('vehicles.views.requests.get')
    def test_api_timeout(self, mock_get):
        """Test handling of request timeout"""
        mock_get.side_effect = requests.Timeout('Connection timeout')

        response = self.client.get(self.url, {'registration': 'AB12345'})

        self.assertEqual(response.status_code, status.HTTP_504_GATEWAY_TIMEOUT)
        self.assertIn('error', response.data)
        self.assertIn('timed out', response.data['error'].lower())

    @patch('vehicles.views.settings.STATENS_VEGVESEN_API_KEY', 'test-api-key')
    @patch('vehicles.views.requests.get')
    def test_api_connection_error(self, mock_get):
        """Test handling of connection error"""
        mock_get.side_effect = requests.RequestException('Connection failed')

        response = self.client.get(self.url, {'registration': 'AB12345'})

        self.assertEqual(response.status_code, status.HTTP_503_SERVICE_UNAVAILABLE)
        self.assertIn('error', response.data)
        self.assertIn('Failed to connect', response.data['error'])

    @patch('vehicles.views.settings.STATENS_VEGVESEN_API_KEY', None)
    def test_missing_api_key(self):
        """Test handling when API key is not configured"""
        response = self.client.get(self.url, {'registration': 'AB12345'})

        self.assertEqual(response.status_code, status.HTTP_500_INTERNAL_SERVER_ERROR)
        self.assertIn('error', response.data)
        self.assertEqual(response.data['error'], 'API key not configured')

    @patch('vehicles.views.settings.STATENS_VEGVESEN_API_KEY', 'test-api-key')
    @patch('vehicles.views.requests.get')
    def test_opplysninger_ikke_tilgjengelige_error(self, mock_get):
        """Test handling of OPPLYSNINGER_IKKE_TILGJENGELIGE error"""
        mock_response = Mock()
        mock_response.status_code = 500
        mock_response.text = 'OPPLYSNINGER_IKKE_TILGJENGELIGE'
        mock_get.return_value = mock_response

        response = self.client.get(self.url, {'registration': 'AB12345'})

        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
        self.assertIn('error', response.data)
        self.assertEqual(response.data['error'], 'Vehicle information not available')

    @patch('vehicles.views.settings.STATENS_VEGVESEN_API_KEY', 'test-api-key')
    @patch('vehicles.views.requests.get')
    def test_empty_kjoretoydataliste(self, mock_get):
        """Test handling of empty kjoretoydataListe in response"""
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            'kjennemerke': 'AB12345',
            'kjoretoydataListe': []
        }
        mock_get.return_value = mock_response

        response = self.client.get(self.url, {'registration': 'AB12345'})

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['brand'], 'N/A')
        self.assertEqual(response.data['model'], 'N/A')
        self.assertEqual(response.data['year'], 'N/A')

    @patch('vehicles.views.settings.STATENS_VEGVESEN_API_KEY', 'test-api-key')
    @patch('vehicles.views.requests.get')
    def test_registration_number_case_insensitive(self, mock_get):
        """Test that registration number is converted to uppercase"""
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = self.mock_success_response
        mock_get.return_value = mock_response

        # Make request with lowercase
        response = self.client.get(self.url, {'registration': 'ab12345'})

        # Verify API was called with uppercase
        call_args = mock_get.call_args
        self.assertEqual(call_args[1]['params']['kjennemerke'], 'AB12345')
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    @patch('vehicles.views.settings.STATENS_VEGVESEN_API_KEY', 'test-api-key')
    @patch('vehicles.views.requests.get')
    def test_public_endpoint_no_auth_required(self, mock_get):
        """Test that endpoint is accessible without authentication"""
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = self.mock_success_response
        mock_get.return_value = mock_response

        # Make request without any authentication
        response = self.client.get(self.url, {'registration': 'AB12345'})

        # Should succeed without authentication
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    @patch('vehicles.views.settings.STATENS_VEGVESEN_API_KEY', 'test-api-key')
    @patch('vehicles.views.requests.get')
    def test_data_extraction_with_minimal_response(self, mock_get):
        """Test data extraction with minimal API response structure"""
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            'kjoretoydataListe': [{
                'godkjenning': {
                    'tekniskGodkjenning': {
                        'tekniskeData': {
                            'generelt': {}
                        }
                    }
                }
            }]
        }
        mock_get.return_value = mock_response

        response = self.client.get(self.url, {'registration': 'AB12345'})

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        # Should return N/A for missing fields
        self.assertEqual(response.data['brand'], 'N/A')
        self.assertEqual(response.data['model'], 'N/A')
