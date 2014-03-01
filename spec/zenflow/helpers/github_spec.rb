require 'spec_helper'

describe Zenflow::Github do
  describe '.system_default_hub' do
    it 'is the expected value' do
      expect(Zenflow::Github.system_default_hub).to eq('github.com')
    end
  end

  describe '.default_hub' do
    context 'when no default github has been specified' do
      before(:each){
        Zenflow::Shell.should_receive(:run).with("git config --get zenflow.default.hub", silent: true).and_return("")
      }

      it "returns the system default github" do
        expect(Zenflow::Github.default_hub).to eq('github.com')
      end
    end

    context 'when a default github has been specified' do
      let(:default_hub){'default-github'}

      before(:each){
        Zenflow::Shell.should_receive(:run).with("git config --get zenflow.default.hub", silent: true).and_return(default_hub)
      }

      it "returns the default github" do
        expect(Zenflow::Github.default_hub).to eq(default_hub)
      end
    end
  end

  describe '.set_default_hub' do
    let(:default_hub){'default-github'}

    it 'asks for the default github and sets it to zenflow.default.hub' do
      Zenflow.should_receive(:Ask).and_return(default_hub)
      Zenflow::Shell.should_receive(:run).with("git config --global zenflow.default.hub #{default_hub}", silent: true)
      Zenflow::Github.set_default_hub
    end
  end

  describe '.api_base_url' do
    context 'when the value is present' do
      before(:each){
        Zenflow::Github.should_receive(:get_hub_config).with('test-hub', 'api.base.url').and_return("api-base-url")
      }

      context 'and default is true' do
        it 'returns the expected value' do
          expect(Zenflow::Github.api_base_url('test-hub', true)).to eq("api-base-url")
        end
      end

      context 'and default is false' do
        it 'returns the expected value' do
          expect(Zenflow::Github.api_base_url('test-hub', false)).to eq("api-base-url")
        end
      end
    end

    context 'when the value is absent' do
      before(:each){
        Zenflow::Github.should_receive(:get_hub_config).with('test-hub', 'api.base.url').and_return(nil)
      }

      context 'and default is true' do
        it 'returns the expected value' do
          expect(Zenflow::Github.api_base_url('test-hub', true)).to eq("https://api.github.com")
        end
      end

      context 'and default is false' do
        it 'returns the expected value' do
          expect(Zenflow::Github.api_base_url('test-hub', false)).to eq(nil)
        end
      end
    end
  end

  describe '.set_api_base_url' do
    let(:api_base_url){'api-base-url'}

    it 'asks for the API base URL and sets it to zenflow.api.base.url' do
      Zenflow.should_receive(:Ask).and_return(api_base_url)
      Zenflow::Github.should_receive(:set_hub_config).with(nil, 'api.base.url', api_base_url)
      Zenflow::Github.set_api_base_url
    end
  end

  describe '.user' do
    let(:user){'github-user'}

    before(:each){
      Zenflow::Github.should_receive(:get_hub_config).with('test-hub', 'github.user').and_return(user)
    }

    it "returns the user" do
      expect(Zenflow::Github.user('test-hub')).to eq(user)
    end
  end

  describe '.set_user' do
    let(:user){'github-user'}

    it 'asks for the user name and sets it to github.user' do
      Zenflow.should_receive(:Ask).and_return(user)
      Zenflow::Github.should_receive(:set_hub_config).with(nil, 'github.user', user)
      Zenflow::Github.set_user
    end
  end

  describe '.authorize' do
    context "when authorization fails" do
      before do
        Zenflow.should_receive("Log").with("Authorizing with GitHub (adamkittelson@github.com)... Enter your GitHub password.")
        Zenflow::Github.should_receive(:user).twice.and_return('adamkittelson')
        Zenflow::Github.should_receive(:api_base_url).and_return('https://api.base.url')
        Zenflow::Shell.should_receive(:run).with(%{curl -u "adamkittelson" https://api.base.url/authorizations -d '{"scopes":["repo"], "note":"Zenflow"}' --silent}, :silent => true).and_return('{"message": "failed to authorize, bummer"}')
      end

      it "logs that something went wrong" do
        Zenflow.should_receive("Log").with("Something went wrong. Error from GitHub was: failed to authorize, bummer")
        Zenflow::Github.authorize
      end
    end

    context "when authorization succeeds" do
      before do
        Zenflow.should_receive("Log").with("Authorizing with GitHub (adamkittelson@github.com)... Enter your GitHub password.")
        Zenflow::Github.should_receive(:user).twice.and_return('adamkittelson')
        Zenflow::Github.should_receive(:api_base_url).and_return('https://api.base.url')
        Zenflow::Shell.should_receive(:run).with(%{curl -u "adamkittelson" https://api.base.url/authorizations -d '{"scopes":["repo"], "note":"Zenflow"}' --silent}, :silent => true).and_return('{"token": "super secure token"}')
      end

      it "adds the token to git config and logs a happy message of success" do
        Zenflow::Github.should_receive(:set_hub_config).with(nil, 'token', "super secure token")
        Zenflow.should_receive("Log").with("Authorized!")
        Zenflow::Github.authorize
      end
    end

  end

  describe '.user_agent_base' do
    context 'when the value is present' do
      before(:each){
        Zenflow::Github.should_receive(:get_hub_config).with('test-hub', 'user.agent.base').and_return("user-agent-base")
      }

      context 'and default is true' do
        it 'returns the expected value' do
          expect(Zenflow::Github.user_agent_base('test-hub', true)).to eq("user-agent-base")
        end
      end

      context 'and default is false' do
        it 'returns the expected value' do
          expect(Zenflow::Github.user_agent_base('test-hub', false)).to eq("user-agent-base")
        end
      end
    end

    context 'when the value is absent' do
      before(:each){
        Zenflow::Github.should_receive(:get_hub_config).with('test-hub', 'user.agent.base').and_return(nil)
      }

      context 'and default is true' do
        it 'returns the expected value' do
          expect(Zenflow::Github.user_agent_base('test-hub', true)).to eq("Zencoder")
        end
      end

      context 'and default is false' do
        it 'returns the expected value' do
          expect(Zenflow::Github.user_agent_base('test-hub', false)).to eq(nil)
        end
      end
    end
  end

  describe '.set_user_agent_base' do
    let(:user_agent_base){'user-agent-base'}

    it 'asks for the User-Agent base string and sets it to zenflow.user.agent.base' do
      Zenflow.should_receive(:Ask).and_return(user_agent_base)
      Zenflow::Github.should_receive(:set_hub_config).with(nil, 'user.agent.base', user_agent_base)
      Zenflow::Github.set_user_agent_base
    end
  end

  describe '.select_hub' do
    context 'when supplied as argument' do
      it 'returns the hub provided' do
        expect(Zenflow::Github.select_hub('test-hub')).to eq 'test-hub'
      end    
    end

    context 'when argument is \'default\'' do
      before(:each){
        Zenflow::Github.should_receive(:default_hub).and_return('default-hub')
      }

      it 'returns the default hub' do
        expect(Zenflow::Github.select_hub('default')).to eq 'default-hub'
      end    
    end

    context 'when argument is nil' do
      context 'and there is a repo hub' do
        before(:each){
          Zenflow::Repo.should_receive(:hub).and_return('repo-hub')
        }

        it 'returns the repo hub' do
          expect(Zenflow::Github.select_hub(nil)).to eq 'repo-hub'
        end    
      end

      context 'and the repo hub is nil' do
        before(:each){
          Zenflow::Repo.should_receive(:hub).and_return(nil)
          Zenflow::Github.should_receive(:default_hub).and_return('default-hub')
        }

        it 'returns the default hub' do
          expect(Zenflow::Github.select_hub(nil)).to eq 'default-hub'
        end    
      end
    end
  end

  describe '.key_for_hub' do
    context 'when hub is the system default hub' do
      context 'and key is the api url base key' do
        it 'prepends \'zenflow\' as a prefix' do
          expect(Zenflow::Github.key_for_hub(Zenflow::Github.system_default_hub, 'api.base.url')).to eq("zenflow.api.base.url")
        end
      end

      context 'and key is the user key' do
        it 'does not prepend a prefix' do
          expect(Zenflow::Github.key_for_hub(Zenflow::Github.system_default_hub, 'github.user')).to eq('github.user')
        end
      end

      context 'and key is the zenflow token key' do
        it 'prepends \'zenflow\' as a prefix' do
          expect(Zenflow::Github.key_for_hub(Zenflow::Github.system_default_hub, 'token')).to eq("zenflow.token")
        end
      end

      context 'and key is the user agent base key' do
        it 'prepends \'zenflow\' as a prefix' do
          expect(Zenflow::Github.key_for_hub(Zenflow::Github.system_default_hub, 'user.agent.base')).to eq("zenflow.user.agent.base")
        end
      end
    end

    context 'hub is not the system default hub' do
      context 'and key is the api url base key' do
        it 'prepends a hub-specific prefix' do
          expect(Zenflow::Github.key_for_hub('my-hub', 'api.base.url')).to eq("zenflow.hub.my-hub.api.base.url")
        end
      end

      context 'and key is the user key' do
        it 'prepends a hub-specific prefix' do
          expect(Zenflow::Github.key_for_hub('my-hub', 'github.user')).to eq("zenflow.hub.my-hub.github.user")
        end
      end

      context 'and key is the zenflow token key' do
        it 'prepends a hub-specific prefix' do
          expect(Zenflow::Github.key_for_hub('my-hub', 'token')).to eq("zenflow.hub.my-hub.token")
        end
      end

      context 'and key is the user agent base key' do
        it 'prepends a hub-specific prefix' do
          expect(Zenflow::Github.key_for_hub('my-hub', 'user.agent.base')).to eq("zenflow.hub.my-hub.user.agent.base")
        end
      end
    end
  end

  describe '.get_hub_config' do
    it 'gets the correct global config parameter' do
      Zenflow::Github.should_receive(:get_global_config).with("zenflow.hub.test-hub.test-key")
      Zenflow::Github.get_hub_config('test-hub', 'test-key')
    end
  end

  describe '.set_hub_config' do
    it 'sets the correct global config parameter' do
      Zenflow::Github.should_receive(:set_global_config).with("zenflow.hub.test-hub.test-key", "test-value")
      Zenflow::Github.set_hub_config('test-hub', 'test-key', 'test-value')
    end
  end

  describe '.get_global_config' do
    context 'when value is present' do
      before(:each){
        Zenflow::Shell.should_receive(:run).with('git config --get key', silent: true).and_return('value')
      }

      it 'returns the value' do
        expect(Zenflow::Github.get_global_config('key')).to eq('value')
      end
    end

    context 'when value is missing' do
      before(:each){
        Zenflow::Shell.should_receive(:run).with('git config --get key', silent: true).and_return('')
      }

      it 'returns nil' do
        expect(Zenflow::Github.get_global_config('key')).to eq(nil)
      end
    end
  end

  describe '.set_global_config' do
    before(:each){
      Zenflow::Shell.should_receive(:run).with('git config --global key value', silent: true)
    }

    it 'sets the value' do
      Zenflow::Github.set_global_config('key', 'value')
    end
  end

end
