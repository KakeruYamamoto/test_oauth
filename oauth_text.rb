


ーーーーーーーーー先にapiを有効化と情報の取得ーーーーーーーーーー

すること
・OAuth認証に必要な情報の取得
・GoogleAPIの有効化


手順1、Google側でOAuth認証に必要なIDとPASSWORDを発行します。
手順2、Google側でAPIの設定を行います。
手順3、OAuthアプリ(クライアントアプリケーション)を立ち上げます。
手順4、Googleのアカウントを利用して、OAuthアプリに
ログインできるように実装します。


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

# devise_for :users, controllers: {
#   registrations: "users/registrations"
# }



Rails.application.routes.draw do
  # この記述を変更
  root :to => 'oauth_test#index'
  devise_for :users, controllers: {
    registrations: "users/registrations",
    # この記述を追記 controller oauth_testを作成後＝＞160行あたりで行う
    omniauth_callbacks: "users/omniauth_callbacks"
  }
end

ーーーーーーーーーーーーーーーーーーーーーーーーーーーー

config/initializers/devise.rb


Devise.setup do |config|
## 省略
config.omniauth :google_oauth2, ENV['GOOGLE_APP_ID'], ENV['GOOGLE_APP_SECRET'], name: :google ##追記
## 省略


ーーーーーーーーーーーーーーーーーーーーーーーーーーーー

#.envファイルを作成して、環境変数を設定
#gem 'dotenv-rails'をインストして作成

.env

GOOGLE_APP_ID=XXXXXXXXX
GOOGLE_APP_SECRET=xxxxxxxxx


ーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーー

コマンド

$ rails g controller oauth_test index

ーーーーーーーーーーーーーーーーーーーーーーーーー

app/views/oauth_test/index.html.erb


<p><%= notice %><%= alert %></p>
<% if user_signed_in? %>
  <%= link_to "ログアウト", destroy_user_session_path, method: :delete %>
<% else %>
  <%= link_to 'Googleでサインアップしてね', user_google_omniauth_authorize_path %>
<% end %>

#終了後localで確認
ーーーーーーーーーーーーーーーーーーーーーーーーーーーーーー

app/controllers/users/omniauth_callbacks_controller.rb

#omniauth_callbacks_controller.rb のファイルを作る


class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google
    @user = User.find_for_google(request.env['omniauth.auth'])
    if @user.persisted?
      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, kind: "google") if is_navigational_format?
    else
      session['devise.google_data'] = request.env['omniauth.auth']
      redirect_to new_user_registration_url
    end
  end
end


ーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーー

最後に「認証情報」にてリダイレクトURIに
http://localhost:3000/users/auth/google/callback
を設定。
ルーティングで確認できる。

完
