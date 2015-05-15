require 'rotp'

module Devise
  module Models
    module GoogleAuthenticatable
      def self.included(base)
        base.extend ClassMethods

        base.class_eval do
          before_validation :assign_auth_secret, :on => :create
          include InstanceMethods
        end
      end

      module InstanceMethods
        def get_qr
          self.gauth_secret
        end

        def set_gauth_enabled(param)
          #self.update_without_password(params[gauth_enabled])
          self.update_attributes(:gauth_enabled => param)
        end

        def assign_tmp
          self.update_attributes(:gauth_tmp => ROTP::Base32.random_base32(32), :gauth_tmp_datetime => DateTime.now)
          self.gauth_tmp
        end

        def validate_token(token)
          return false if self.gauth_tmp_datetime.nil?
          return false if self.gauth_tmp_datetime < self.class.ga_timeout.ago
          return true if invalidate_backup_code!(token)

          valid_vals = []
          valid_vals << ROTP::TOTP.new(self.get_qr).at(Time.now)
          (1..self.class.ga_timedrift).each do |cc|
            valid_vals << ROTP::TOTP.new(self.get_qr).at(Time.now.ago(30*cc))
            valid_vals << ROTP::TOTP.new(self.get_qr).at(Time.now.in(30*cc))
          end

          valid_vals.include?(token.to_i) ? true : false
        end

        def gauth_enabled?
          # Active_record seems to handle determining the status better this way
          if self.gauth_enabled.respond_to?('to_i')
            self.gauth_enabled.to_i != 0 ? true : false
          else
            # Mongoid does NOT have a .to_i for the Boolean return value, hence, we can just return it
            self.gauth_enabled
          end
        end

        def require_token?(cookie)
          return true if self.class.ga_remembertime.nil? || cookie.blank?
          array = cookie.to_s.split ','
          return true if array.count != 2
          last_logged_in_email = array[0]
          last_logged_in_time = array[1].to_i
          last_logged_in_email != self.email || (Time.now.to_i - last_logged_in_time) > self.class.ga_remembertime.to_i
        end

        def max_login_attempts?
          gauth_attempts_count.to_i >= ga_max_login_attempts.to_i
        end

        def ga_max_login_attempts
          self.class.ga_max_login_attempts
        end

        # backup codes

        def generate_backup_codes!
          codes           = []
          code_length     = self.class.ga_backup_code_length
          number_of_codes = self.class.ga_number_of_backup_codes

          number_of_codes.times do
            codes << SecureRandom.hex(code_length / 2) # Hexstring has length 2*n
          end

          hashed_codes = codes.map { |code| Devise.bcrypt self.class, code }
          self.gauth_backup_codes = hashed_codes
          self.save

          codes
        end

        def invalidate_backup_code!(code)
          codes = self.gauth_backup_codes || []

          codes.each do |backup_code|
            # We hashed the code with Devise.bcrypt, so if Devise changes that
            # method, we'll have to adjust our comparison here to match it
            # TODO Fork Devise and encapsulate this logic in a helper
            bcrypt      = ::BCrypt::Password.new(backup_code)
            hashed_code = ::BCrypt::Engine.hash_secret("#{code}#{self.class.pepper}", bcrypt.salt)

            next unless Devise.secure_compare(hashed_code, backup_code)

            codes.delete(backup_code)
            self.gauth_backup_codes = codes
            self.save
            return true
          end

          false
        end

        private

        def assign_auth_secret
          self.gauth_secret = ROTP::Base32.random_base32(64)
        end
      end

      module ClassMethods
        def find_by_gauth_tmp(gauth_tmp)
          where(gauth_tmp: gauth_tmp).first
        end

        ::Devise::Models.config(self, :ga_timeout, :ga_timedrift, :ga_remembertime, :ga_appname, :ga_bypass_signup,
                                :ga_max_login_attempts, :ga_backup_code_length, :ga_number_of_backup_codes)
      end
    end
  end
end
