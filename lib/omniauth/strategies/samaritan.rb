require 'omniauth/strategies/oauth2'

module OmniAuth
  module Strategies
    class Samaritan < OmniAuth::Strategies::OAuth2

      option :name, 'samaritan'
      option :environment

      option :client_options, {}

      option :sandbox_client_options, {
          :authorize_url => 'https://sandbox.smchcn.net/asrv/smi/oauth/authorize',
          :token_url     => 'https://sandbox.smchcn.net/asrv/smi/oauth/token',
          :identity_url  => 'https://sandbox.smchcn.net/smi/api/identity/mine'}

      option :production_client_options, {
          :authorize_url => 'https://accounts.samaritanministries.org/auth',
          :token_url     => 'https://accounts.samaritanministries.org/auth/smi/oauth/token',
          :identity_url  => 'https://platformapi.samaritanministries.org/smi/api/identity/mine'}

      def client_options
        client_options = options.client_options
        client_options = options.sandbox_client_options if options.environment == :sandbox
        client_options = options.production_client_options if options.environment == :production
        client_options
      end

      def request_phase
        if request.params['access_token']
          self.access_token = build_access_token_from_params(request.params)
          env['omniauth.auth'] = auth_hash
          call_app!
        else
          super
        end
      end

      def client
        ::OAuth2::Client.new(options.client_id, options.client_secret, deep_symbolize(client_options))
      end

      def token_params
        super.merge({:headers => {'Authorization' => authorization(options.client_id, options.client_secret)}})
      end

      def authorization(client_id, client_secret)
        'Basic ' + Base64.encode64(client_id + ':' + client_secret).gsub("\n", '')
      end

      uid { raw_info['id'] }

      info do
        prune!({
          :name                   => raw_info['nickname'],
          :email                  => raw_info['email_address'],
          :member_id              => raw_info['member_id'],
          :membership_id          => raw_info['context'],
          :is_approved            => raw_info['is_approved'],
          :has_claimed_membership => raw_info['has_claimed_membership'],
          :is_locked_out          => raw_info['is_locked_out']
        })
      end

      extra do
        hash = {}
        hash[:raw_info] = raw_info unless skip_info?
        prune! hash
      end

      def raw_info
        identity_endpoint = client_options[:site].to_s.gsub(/\/\z/, '') + client_options[:identity_url].to_s
        @raw_info ||= access_token.get(identity_endpoint).parsed
      end

      private

      def build_access_token_from_params(params)
        ::OAuth2::AccessToken.new(client, params['access_token'])
      end

      def prune!(hash)
        hash.delete_if do |_, v|
          prune!(v) if v.is_a?(Hash)
          v.nil? || (v.respond_to?(:empty?) && v.empty?)
        end
      end

    end
  end
end
