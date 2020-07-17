package com.flutter.aliyunPush;

import io.flutter.app.FlutterApplication;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MyApplication extends FlutterApplication implements PluginRegistry.PluginRegistrantCallback {

    @Override
    public void onCreate() {
        super.onCreate();
    }

    @Override
    public void registerWith(PluginRegistry registry) {
        AliyunPushPlugin.registerWith(
                registry.registrarFor("com.flutter.aliyunPush.AliyunPushPlugin"));
    }
}
