module Zenflow
  class Hubs < Thor

    desc "show_default", "Show the default hub"
    def show_default(hub=nil)
      Zenflow::Log("Default hub: #{default_hub_label(Zenflow::Github.default_hub)}")
    end

    desc "set_default", "Set the default hub"
    def set_default
      if Zenflow::Ask("The default hub is currently #{default_hub_label(Zenflow::Github.default_hub)}.  Do you want to change that?", :options => ["y", "N"], :default => "N") == "y"
        Zenflow::Github.set_default_hub
      end
    end

    desc "list", "Show all configured hubs."
    def list
      config = Zenflow::Shell.run("git config -l", silent: true).split("\n")
      hub_parameter_records = config.select { |entry| entry =~ /^zenflow\.hub\.(.*)\.#{config_keys_regex}=.*$/ }
      hub_parameter_records = hub_parameter_records.map { |entry| entry =~ /^zenflow\.hub\.(.*)\.#{config_keys_regex}=.*$/; hub_label($1) }
      hub_parameter_records = hub_parameter_records.sort.uniq
      rows = hub_parameter_records.map { |record| [record] }
      rows = [
        ["Hub"],
        ["----"],
        ["#{hub_label(Zenflow::Github.default_hub)}"]
      ] + rows
      Zenflow::Log("Recogized hubs")
      Zenflow::Log(Terminal::Table.new(rows: rows).to_s, indent: false, arrows: false, color: false)
    end

    desc "current", "Show the current project's hub."
    def current
      Zenflow::Log("This project's hub is #{hub_label(Zenflow::Repo.hub)}")
    end

    desc "describe [HUB]", "Show configuration details for HUB (current project hub if none specified, or default hub if no current project)."
    def describe(hub=nil)
      hub = Zenflow::github.select_hub(hub)

      Zenflow::Log("Configuration details for hub #{hub_label(hub)}")

      Zenflow::Log(Terminal::Table.new(rows: [
        ["Parameter", "Github Config Key", "Github Config Value", "Value (with system defaults)"],
        ["---------", "-----------------", "-------------------", "----------------------------"]
      ] + describe_hub_parameters(hub)
      ).to_s, indent: false, arrows: false, color: false)
    end

    desc "config [HUB]", "Configure the specified HUB (current project hub if none specified, or default hub if no current project)."
    def config(hub=nil)
      hub = Zenflow::github.select_hub(hub)

      Zenflow::Log("Configuring #{hub_label(hub)}")

      api_base_url = Zenflow::Github.api_base_url(hub,false)
      if api_base_url.to_s != ''
        if Zenflow::Ask("The GitHub API base URL for this hub is currently #{api_base_url}. Do you want to use that?", :options => ["Y", "n"], :default => "y") == "n"
          Zenflow::Github.set_api_base_url(hub)
        end
      else
        Zenflow::Github.set_api_base_url(hub)
      end

      user = Zenflow::Github.user(hub)
      if user.to_s != ''
        if Zenflow::Ask("The GitHub user for this hub is currently #{user}. Do you want to use that?", :options => ["Y", "n"], :default => "y") == "n"
          Zenflow::Github.set_user(hub)
        end
      else
        Zenflow::Github.set_user(hub)
      end

      user_agent_base = Zenflow::Github.user_agent_base(hub,false)
      if user_agent_base.to_s != ''
        if Zenflow::Ask("The GitHub User Agent base for this hub is currently #{user_agent_base}. Do you want to use that?", :options => ["Y", "n"], :default => "y") == "n"
          Zenflow::Github.set_user_agent_base(hub)
        end
      else
        Zenflow::Github.set_user_agent_base(hub)
      end
    end

    desc "authorize [HUB]", "Grab an auth token for HUB (current project hub if none specified, or default hub if no current project)."
    def authorize(hub=nil)
      hub = Zenflow::github.select_hub(hub)

      if Zenflow::Github.zenflow_token(hub)
        if Zenflow::Ask("You already have a token from GitHub. Do you want to set a new one?", :options => ["y", "N"], :default => "n") == "y"
          Zenflow::Github.authorize(hub)
        end
      else
        Zenflow::Github.authorize(hub)
      end
    end

    no_commands {
      def default_hub_label(hub)
        "#{hub}#{hub == Zenflow::Github.system_default_hub ? ' [system default]' : ''}"
      end

      def hub_label(hub)
        "#{hub}#{default_hub_tag(hub)}#{current_hub_tag(hub)}"
      end

      def default_hub_tag(hub)
        Zenflow::Repo.is_default_hub(hub) ? " [default]" : ""
      end

      def current_hub_tag(hub)
        Zenflow::Repo.is_current_hub(hub) ? " [current]" : ""
      end

      def describe_hub_parameter_record(name, hub, key, value)
        [name, config_key(hub, key), config_value(hub, key), value]
      end

      def config_key(hub, key)
        Zenflow::Github.key_for_hub(hub, key)
      end

      def config_value(hub, key)
        Zenflow::Github.get_hub_config(hub, key)
      end

      def config_keys_regex
        config_keys = [
            Zenflow::Github.api_base_url_key,
            Zenflow::Github.user_key,
            Zenflow::Github.token_key,
            Zenflow::Github.user_agent_base_key
        ]
        "(?:#{config_keys.map { |s| s.gsub('.','\\.') }.join('|')})"
      end

      def describe_hub_parameters(hub)
        [
          describe_hub_parameter_record("API base URL",    hub, Zenflow::Github.api_base_url_key,    Zenflow::Github.api_base_url(hub)),
          describe_hub_parameter_record("User",            hub, Zenflow::Github.user_key,            Zenflow::Github.user(hub)),
          describe_hub_parameter_record("Token",           hub, Zenflow::Github.token_key,           Zenflow::Github.zenflow_token(hub)),
          describe_hub_parameter_record("User Agent Base", hub, Zenflow::Github.user_agent_base_key, Zenflow::Github.user_agent_base(hub))
        ]
      end
    }
  end
end
