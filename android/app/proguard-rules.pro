# Não apagar as classes do Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Não apagar as classes de Notificação (Essencial!)
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.google.type.DateTime { *; }
-keep class com.google.type.Date { *; }
-keep class com.google.type.TimeOfDay { *; }

# Não apagar o Hive (Banco de dados)
-keep class com.hivedb.** { *; }
-dontwarn com.hivedb.**

# Ignorar avisos de classes ausentes da Play Store (Resolve o erro do R8)
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Se quiser ser ainda mais específico para as classes do erro:
-keep class com.google.android.play.core.** { *; }

# Ignorar erros de bibliotecas de terceiros durante a otimização
-ignorewarnings
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-keepattributes Signature

# Manter classes do Supabase e Postgrest
-keep class io.supabase.** { *; }
-keep class jsonObjects.** { *; }

# Manter o que o Flutter usa internamente
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }