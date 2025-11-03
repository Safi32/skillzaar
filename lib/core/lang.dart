import 'package:flutter/material.dart';

const Map<String, Map<String, String>> langMap = {
  'availableJobs': {'en': 'Available Jobs', 'ur': 'دستیاب نوکریاں'},
  'noJobs': {'en': 'No jobs available.', 'ur': 'کوئی نوکری دستیاب نہیں۔'},
  'noJobsMatch': {
    'en': 'No jobs match your filters.',
    'ur': 'آپ کی فلٹرز سے کوئی نوکری نہیں ملی۔',
  },
  'monthlyAccess': {
    'en': 'Monthly Access Fee Required',
    'ur': 'ماہانہ فیس درکار ہے',
  },
  'payMsg': {
    'en':
        'To view jobs, please pay the monthly fee of PKR 100 via Easypaisa, JazzCash, or card.',
    'ur': 'نوکریاں دیکھنے کے لیے براہ کرم PKR 100 ماہانہ فیس ادا کریں۔',
  },
  'payNow': {'en': 'Pay Now', 'ur': 'ابھی ادا کریں'},
  'paymentSuccess': {
    'en': 'Payment successful! You can now view jobs.',
    'ur': 'ادائیگی کامیاب! آپ اب نوکریاں دیکھ سکتے ہیں۔',
  },
  'jobType': {'en': 'Job Type', 'ur': 'کام کی قسم'},
  'distance': {'en': 'Distance', 'ur': 'فاصلہ'},
  'kmAway': {'en': '{distance} km away', 'ur': '{distance} کلومیٹر دور'},
  'calendar': {'en': 'Unknown date', 'ur': 'نامعلوم تاریخ'},
  // Add more keys as needed
};

String tr(BuildContext context, String key, {Map<String, String>? params}) {
  String value = langMap[key]?['en'] ?? key;
  if (params != null) {
    params.forEach((k, v) {
      value = value.replaceAll('{$k}', v);
    });
  }
  return value;
}
