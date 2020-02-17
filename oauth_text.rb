


ーーーーーーーーー先にapiを有効化と情報の取得ーーーーーーーーーー

すること
・OAuth認証に必要な情報の取得
・GoogleAPIの有効化

参照：OAuth7【OAuth認証に必要な情報の取得とGoogleAPIの有効化について】（https://diver.diveintocode.jp/curriculums/659）



立ち上げーーーーーーー

$ rails _5.2.3_ new oauth -d postgresql

↓

確認
$ rails s

ーーーーーーーーーーーーーーーーーーーー

gemfile

gem 'devise'
gem 'omniauth'
gem 'omniauth-google-oauth2'

$ bundle install

↓ーーー

deviseインスト〜user〜マイグレート

$ rails g devise:install

$ rails g devise user


ーdb/migrate/XXXXX_devise_create_users.rbー

class DeviseCreateUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :users do |t|
      t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""
      t.string :provider, null: false, default: "" ##追記
      t.string :uid, null: false, default: "" ##追記
・・・省略・・・
      ## Trackable
      t.integer  :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.inet     :current_sign_in_ip
      t.inet     :last_sign_in_ip
・・・省略・・・
    end
    add_index :users, [:uid, :provider], unique: true ##追記
・・・省略・・・
  end
end

ーーーーー


$ rails db:migrate

$ rails g controller users::registrations

ーーーーーーーーーーーーーーーーーーー


app/controllers/users/registrations_controller


class Users::RegistrationsController < Devise::RegistrationsController
  def build_resource(hash={})
    hash[:uid] = User.create_unique_string
    super
  end
end

ーーーーーーーーーーーーーーーーーーーーーーーーーーーーー

app/models/user.rb

class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,:omniauthable, omniauth_providers: %i(google)
  def self.create_unique_string
    SecureRandom.uuid
  end
  def self.find_for_google(auth)
    user = User.find_by(email: auth.info.email)
    unless user
      user = User.new(email: auth.info.email,
                      provider: auth.provider,
                      uid:      auth.uid,
                      password: Devise.friendly_token[0, 20],
                                 )
    end
    user.save
    user
  end
end


ーーーーーーーーーーーーーーーーーーーーーーーーー

config/routes.rb

devise_for :users, controllers: {
  registrations: "users/registrations"
}
