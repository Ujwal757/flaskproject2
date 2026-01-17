import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import '../models/report.dart';

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY not found in .env file');
    }

    // Try gemini-1.5-flash first, fallback to gemini-pro-vision if not available
    try {
      _model = GenerativeModel(
        model: 'gemini-flash-lite-latest',
        apiKey: apiKey,
      );
      print('✅ Using model: gemini-1.5-flash');
    } catch (e) {
      print('⚠️ gemini-1.5-flash not available, trying gemini-pro-vision...');
      _model = GenerativeModel(model: 'gemini-pro-vision', apiKey: apiKey);
      print('✅ Using model: gemini-pro-vision');
    }
  }

  /// Step 1: Validate if the image is a road surface
  /// Returns true if it's a road, false otherwise
  Future<bool> validateRoadSurface(XFile imageFile) async {
    try {
      print('📸 Reading image bytes for road validation...');
      final imageBytes = await imageFile.readAsBytes();
      print('✅ Image bytes read: ${imageBytes.length} bytes');

      final prompt = '''
Analyze this image. Is this a road surface? 
Return a JSON response with this exact format:
{
  "isRoad": true or false
}

If it is not a road surface, set isRoad to false.
''';

      print('🤖 Sending request to Gemini API for road validation...');
      final content = [
        Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)]),
      ];

      final response = await _model.generateContent(content);
      final responseText = response.text ?? '';
      print(
        '📥 Gemini API response received: ${responseText.substring(0, responseText.length > 100 ? 100 : responseText.length)}...',
      );

      // Try to extract JSON from the response
      final jsonMatch = RegExp(
        r'\{[^}]*"isRoad"[^}]*\}',
      ).firstMatch(responseText);
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0);
        print('📋 Extracted JSON: $jsonStr');
        final jsonData = json.decode(jsonStr!);
        final isRoad = jsonData['isRoad'] == true;
        print('🛣️ Road validation result: $isRoad');
        return isRoad;
      }

      // Fallback: check if response contains "true" or "yes"
      final fallbackResult =
          responseText.toLowerCase().contains('true') ||
          responseText.toLowerCase().contains('yes');
      print('⚠️ Using fallback validation: $fallbackResult');
      return fallbackResult;
    } catch (e, stackTrace) {
      print('❌ ERROR in validateRoadSurface:');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Error validating road surface: $e');
    }
  }

  /// Step 2: Detect damage and analyze severity
  /// Returns a Map with damage information
  Future<Map<String, dynamic>> detectDamage(XFile imageFile) async {
    try {
      print('📸 Reading image bytes for damage detection...');
      final imageBytes = await imageFile.readAsBytes();
      print('✅ Image bytes read: ${imageBytes.length} bytes');

      final prompt = '''
Analyze this road image for damage. Detect potholes, cracks, or other road damage.
Return a JSON response with this exact format:
{
  "damageDetected": true or false,
  "damageType": "Pothole" or "Crack" or "None",
  "severity": "Minor" or "Moderate" or "Severe",
  "description": "A brief description of the damage found"
}

Severity guidelines:
- Minor: Small cracks or minor surface issues that don't pose immediate danger
- Moderate: Noticeable potholes or cracks that should be addressed soon
- Severe: Large potholes, deep cracks, or significant damage that requires immediate attention

If no damage is detected, set damageDetected to false, damageType to "None", and severity to "Minor".
''';

      print('🤖 Sending request to Gemini API for damage detection...');
      final content = [
        Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)]),
      ];

      final response = await _model.generateContent(content);
      final responseText = response.text ?? '';
      print(
        '📥 Gemini API response received: ${responseText.substring(0, responseText.length > 200 ? 200 : responseText.length)}...',
      );

      // Try to extract JSON from the response
      final jsonMatch = RegExp(
        r'\{[^}]*"damageDetected"[^}]*"description"[^}]*\}',
        dotAll: true,
      ).firstMatch(responseText);

      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0);
        print('📋 Extracted JSON: $jsonStr');
        final jsonData = json.decode(jsonStr!);

        final result = {
          'damageDetected': jsonData['damageDetected'] ?? false,
          'damageType': jsonData['damageType'] ?? 'None',
          'severity': jsonData['severity'] ?? 'Minor',
          'description': jsonData['description'] ?? 'No description available',
        };
        print('✅ Damage detection result: $result');
        return result;
      }

      // Fallback: return default values if JSON parsing fails
      print('⚠️ JSON parsing failed, using fallback values');
      print('📝 Full response text: $responseText');
      return {
        'damageDetected': false,
        'damageType': 'None',
        'severity': 'Minor',
        'description': 'Unable to analyze image. Please try again.',
      };
    } catch (e, stackTrace) {
      print('❌ ERROR in detectDamage:');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Error detecting damage: $e');
    }
  }

  /// Combined method: Validate and detect damage in one call (OPTIMIZED)
  /// Returns null if not a road, otherwise returns damage analysis
  /// This is faster as it makes only ONE API call instead of two
  Future<Map<String, dynamic>?> analyzeRoadImage(XFile imageFile) async {
    try {
      print('📸 Reading image bytes for combined analysis...');
      final imageBytes = await imageFile.readAsBytes();
      print('✅ Image bytes read: ${imageBytes.length} bytes');

      final prompt = '''
Analyze this image. First, determine if this is a road surface. If it is NOT a road surface, return isRoad: false.
If it IS a road surface, analyze it for damage (potholes, cracks, or other road damage).

Return a JSON response with this exact format:
{
  "isRoad": true or false,
  "damageDetected": true or false (only if isRoad is true),
  "damageType": "Pothole" or "Crack" or "None" (only if isRoad is true),
  "severity": "Minor" or "Moderate" or "Severe" (only if isRoad is true),
  "description": "A brief description" (only if isRoad is true)
}

If isRoad is false, you can omit the other fields or set them to null.
If isRoad is true but no damage is detected, set damageDetected to false, damageType to "None", and severity to "Minor".

Severity guidelines (only if damage is detected):
- Minor: Small cracks or minor surface issues that don't pose immediate danger
- Moderate: Noticeable potholes or cracks that should be addressed soon
- Severe: Large potholes, deep cracks, or significant damage that requires immediate attention
''';

      print('🤖 Sending combined request to Gemini API...');
      final content = [
        Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)]),
      ];

      final response = await _model.generateContent(content);
      final responseText = response.text ?? '';
      print(
        '📥 Gemini API response received: ${responseText.substring(0, responseText.length > 200 ? 200 : responseText.length)}...',
      );

      // Try to extract JSON from the response - handle both "isRoad" and "Road" keys
      // Look for JSON objects that contain road-related fields
      final jsonPatterns = [
        r'\{[^}]*"(?:isRoad|Road|road)"[^}]*\}', // Simple pattern
        r'\{[^}]*"damageDetected"[^}]*\}', // Alternative pattern
        r'\{.*?"(?:isRoad|Road|road)".*?\}', // More flexible pattern
      ];

      Map<String, dynamic>? jsonData;
      String? jsonStr;

      for (final pattern in jsonPatterns) {
        final jsonMatch = RegExp(
          pattern,
          dotAll: true,
        ).firstMatch(responseText);
        if (jsonMatch != null) {
          jsonStr = jsonMatch.group(0);
          try {
            jsonData = json.decode(jsonStr!);
            break; // Successfully parsed, exit loop
          } catch (e) {
            // Try next pattern
            continue;
          }
        }
      }

      // If simple patterns didn't work, try to find any JSON object
      if (jsonData == null) {
        final anyJsonMatch = RegExp(
          r'\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}',
          dotAll: true,
        ).firstMatch(responseText);
        if (anyJsonMatch != null) {
          jsonStr = anyJsonMatch.group(0);
          try {
            jsonData = json.decode(jsonStr!);
          } catch (e) {
            print('⚠️ Could not parse JSON: $e');
          }
        }
      }

      if (jsonData != null) {
        print('📋 Extracted JSON: $jsonStr');

        // Handle both "isRoad" and "Road" keys (Gemini sometimes uses different field names)
        final isRoad =
            jsonData['isRoad'] == true ||
            jsonData['Road'] == true ||
            jsonData['road'] == true;

        if (!isRoad) {
          print('❌ Image is not a road surface');
          return null; // Not a road surface
        }

        // It's a road, return damage analysis
        final result = {
          'damageDetected': jsonData['damageDetected'] ?? false,
          'damageType': jsonData['damageType'] ?? 'None',
          'severity': jsonData['severity'] ?? 'Minor',
          'description': jsonData['description'] ?? 'No description available',
        };
        print('✅ Combined analysis result: $result');
        return result;
      }

      // Fallback: try to determine if it's a road from text
      final lowerText = responseText.toLowerCase();
      if (lowerText.contains('not a road') ||
          lowerText.contains('not road') ||
          lowerText.contains('is not a road')) {
        print('❌ Image is not a road surface (from fallback)');
        return null;
      }

      // If we can't parse but response seems positive, return default
      print('⚠️ JSON parsing failed, using fallback values');
      return {
        'damageDetected': false,
        'damageType': 'None',
        'severity': 'Minor',
        'description': 'Unable to fully analyze image. Please try again.',
      };
    } catch (e, stackTrace) {
      print('❌ ERROR in analyzeRoadImage:');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Error analyzing road image: $e');
    }
  }

  /// Helper method to convert string severity to enum
  static DamageSeverity parseSeverity(String severity) {
    switch (severity.toLowerCase()) {
      case 'severe':
        return DamageSeverity.severe;
      case 'moderate':
        return DamageSeverity.moderate;
      case 'minor':
      default:
        return DamageSeverity.minor;
    }
  }

  /// Helper method to convert string damage type to enum
  static DamageType parseDamageType(String damageType) {
    switch (damageType.toLowerCase()) {
      case 'pothole':
        return DamageType.pothole;
      case 'crack':
        return DamageType.crack;
      case 'none':
      default:
        return DamageType.none;
    }
  }
}
