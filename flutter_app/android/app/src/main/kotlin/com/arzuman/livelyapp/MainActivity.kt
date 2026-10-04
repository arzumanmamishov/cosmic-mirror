package com.arzuman.livelyapp

import io.flutter.embedding.android.FlutterFragmentActivity

// A FragmentActivity host is kept on purpose: fragment-based plugin UIs
// (e.g. RevenueCat paywalls / Google Play billing flows) need it, and it is
// a drop-in replacement for FlutterActivity.
class MainActivity : FlutterFragmentActivity()
