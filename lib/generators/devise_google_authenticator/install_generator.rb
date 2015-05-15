module DeviseGoogleAuthenticator
  module Generators # :nodoc:
    # Install Generator
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("../../templates", __FILE__)

      desc "Install the devise google authenticator extension"

      def add_configs
        inject_into_file "config/initializers/devise.rb", "\n  # ==> Devise Google Authenticator Extension\n  # Configure extension for devise\n\n" +
        "  # Maximum login attempts:\n" +
        "  # config.ga_max_login_attempts = 3\n\n" +
        "  # How long should the user have to enter their token. To change the default, uncomment and change the below:\n" +
        "  # config.ga_timeout = 3.minutes\n\n" +
        "  # Change time drift settings for valid token values. To change the default, uncomment and change the below:\n" +
        "  # config.ga_timedrift = 3\n\n" +
        "  # Change setting to how long to remember device before requiring another token. Change to nil to turn feature off.\n" +
        "  # To change the default, uncomment and change the below:\n" +
        "  # config.ga_remembertime = 1.month\n\n" +
        "  # Change setting to assign the application name used by code generator. Defaults to Rails.application.class.parent_name.\n" +
        "  # To change the default, uncomment and change the below:\n" +
        "  # config.ga_appname = 'example.com'\n\n" +
        "  # Change setting to bypass the Display QR page immediately after a user sign's up\n" +
        "  # To change the default, uncomment and change the below. Defaults to false:\n" + 
        "  # config.ga_bypass_signup = true\n\n" +
        "  # The length of backup codes:\n" +
        "  # config.ga_backup_code_length = 16\n\n" +
        "  # Number of backup codes:\n" +
        "  # config.ga_number_of_backup_codes = 5\n\n" +
        "\n", :before => /end[ |\n|]+\Z/
      end

      def copy_locale
        copy_file "../../../config/locales/en.yml", "config/locales/devise.google_authenticator.en.yml"
      end
    end
  end
end