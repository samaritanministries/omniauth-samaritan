require 'spec_helper'
require 'omniauth-samaritan'

describe OmniAuth::Strategies::Samaritan do
  let(:request) { double('Request', :params => {}, :cookies => {}, :env => {}) }
  let(:app) {
    lambda do
      [200, {}, ["Hello."]]
    end
  }

  subject do
    OmniAuth::Strategies::Samaritan.new(app, 'appid', 'secret', @options || {}).tap do |strategy|
      strategy.stub(:request) {
        request
      }
    end
  end

  before do
    OmniAuth.config.test_mode = true
  end

  after do
    OmniAuth.config.test_mode = false
  end

  describe '#client_options' do
    it 'has correct site for sandbox' do
      @options = {:environment => :sandbox}
      subject.client.site.should eq('https://sandbox.smchcn.net/')
    end

    it 'has correct site for production' do
      @options = {:environment => :production}
      subject.client.site.should eq('https://api.smchcn.net/')
    end

    it 'has correct authorize_url' do
      @options = {:environment => :production}
      subject.client.options[:authorize_url].should eq('/asrv/smi/oauth/authorize')
    end

    it 'has correct token_url' do
      @options = {:environment => :production}
      subject.client.options[:token_url].should eq('/asrv/smi/oauth/token')
    end

    describe "overrides" do
      it 'should allow overriding the site' do
        @options = {:client_options => {'site' => 'https://example.com'}}
        subject.client.site.should == 'https://example.com'
      end

      it 'should allow overriding the authorize_url' do
        @options = {:client_options => {'authorize_url' => 'https://example.com'}}
        subject.client.options[:authorize_url].should == 'https://example.com'
      end

      it 'should allow overriding the token_url' do
        @options = {:client_options => {'token_url' => 'https://example.com'}}
        subject.client.options[:token_url].should == 'https://example.com'
      end
    end
  end

  describe '#token_params' do
    it 'should include any token params passed in the :token_params option' do
      @options = {:token_params => {:foo => 'bar', :baz => 'zip'}}
      subject.token_params['foo'].should eq('bar')
      subject.token_params['baz'].should eq('zip')
    end
  end

  describe "#token_options" do
    it 'should include top-level options that are marked as :token_options' do
      @options = {:token_options => [:scope, :foo], :scope => 'bar', :foo => 'baz', :bad => 'not_included'}
      subject.token_params['scope'].should eq('bar')
      subject.token_params['foo'].should eq('baz')
      subject.token_params['bad'].should eq(nil)
    end
  end

  describe '#callback_path' do
    it 'has the correct callback path' do
      subject.callback_path.should eq('/auth/samaritan/callback')
    end
  end

  describe '#extra' do
    let(:client) do
      OAuth2::Client.new('abc', 'def') do |builder|
        builder.request :url_encoded
        builder.adapter :test do |stub|
          stub.get('/SmiIdentity/api/identity/mine') {|env| [200, {'content-type' => 'application/json'}, '{"id": "12345"}']}
        end
      end
    end
    let(:access_token) { OAuth2::AccessToken.from_hash(client, {}) }

    before do
      @options = { :environment => :sandbox }
      subject.stub(:access_token => access_token)
    end


    describe 'raw_info' do
      context 'when skip_info is false' do

        it 'should include raw_info' do
          subject.extra[:raw_info].should eq('id' => '12345')
        end
      end
    end

  end

  describe 'populate auth hash urls' do
    it 'should populate url map in auth hash if link present in raw_info' do
      subject.stub(:raw_info){{"id" => "765b1357-8cb5-4b3e-a4bb-239e3af38399","email_address"=>"gotteo@gmail.com","is_approved"=>true,"is_locked_out"=>false,"sub"=>"765b1357-8cb5-4b3e-a4bb-239e3af38399","member_id"=>"44561","context"=>"14470","has_claimed_membership"=>true,"nickname"=>"Greg Otte"}}
      subject.info.should_not have_key(:urls)
      subject.info[:name].should == "Greg Otte"
      subject.info[:email].should == "gotteo@gmail.com"
      subject.info[:is_approved].should == true
      subject.info[:has_claimed_membership].should == true
      subject.info[:is_locked_out].should == false
      subject.info[:member_id].should == "44561"
      subject.info[:membership_id].should == "14470"
    end

  end

  describe "pre-authorized" do
    it "should create an access token" do
      subject.stub(:env){ {}}
      subject.should_receive(:call_app!)
      subject.stub(:raw_info){{"id" => "765b1357-8cb5-4b3e-a4bb-239e3af38399","email_address"=>"gotteo@gmail.com","is_approved"=>true,"is_locked_out"=>false,"sub"=>"765b1357-8cb5-4b3e-a4bb-239e3af38399","member_id"=>"44561","context"=>"14470","has_claimed_membership"=>true,"nickname"=>"Greg Otte"}}
      request.params["access_token"] = "1234567890"
      subject.request_phase
      subject.access_token.should_not be_nil
    end

  end

end
