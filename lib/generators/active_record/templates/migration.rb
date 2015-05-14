class DeviseGoogleAuthenticatorAddTo<%= table_name.camelize %> < ActiveRecord::Migration
  def self.up
    change_table :<%= table_name %> do |t|
      t.string  :gauth_secret, :gauth_token
      t.string  :gauth_enabled, :default => "f"
      t.string  :gauth_tmp
      t.datetime  :gauth_tmp_datetime
      t.integer  :gauth_attempts_count, :default => 0
      t.string :gauth_backup_codes, array: true
  end

  end

  def self.down
    change_table :<%= table_name %> do |t|
      t.remove :gauth_secret, :gauth_enabled, :gauth_tmp, :gauth_tmp_datetime, :gauth_attempts_count, :gauth_backup_codes
    end
  end
end
