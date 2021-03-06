module IptablesWeb
  class Cli
    module Command
      module Install
        def install_command
          command :install do |c|
            c.syntax = 'iptables-web install'
            c.description = 'Displays foo'
            c.option '--force', 'Force config '
            c.action do |args, options|
              config = IptablesWeb::Configuration.new
              api_url = ask('Api base url: ') { |q| q.default = config['api_base_url'] }
              token = ask('Access token: ') { |q| q.default = config['access_token'] }
              update_period = ask('Update every [min]', Integer) { |q| q.default = 1; q.in = 0..59 }
              config_dir = IptablesWeb::Configuration.config_dir
              unless File.exist?(config_dir)
                say "Create config directory: #{config_dir}"
                Dir.mkdir(config_dir)
              end
              config_file = File.join(config_dir, 'config.yml')
              say "Write config to #{config_file}"
              File.write config_file, <<CONFIG
api_base_url: #{api_url}
access_token: #{token}
CONFIG
              if system("LANG=C bash -l -c \"type rvm | cat | head -1 | grep -q '^rvm is a function$'\"")
                wrapper = "#{ENV['HOME']}/.rvm/wrappers/#{`rvm current`.strip}/iptables-web"
              else
                wrapper = 'iptables-web'
              end

              cron_file = File.join(config_dir, 'cron.sh')
              say "Write file #{cron_file}"
              File.write cron_file, <<CONFIG
#/bin/env ruby
#{wrapper} update
CONFIG
              File.chmod(0700, cron_file)
              say "Add cronjob #{cron_file}"
              crontab = IptablesWeb::Crontab.new(false)
              jobs = crontab.jobs
              jobs.reject! { |job| job.include?('.iptables-web') }
              jobs << "*/#{update_period} * * * * #{File.join(ENV['HOME'], '.iptables-web', 'cron.sh')}"
              crontab.save(jobs)

              static_rules = File.join(config_dir, 'static_rules')

              say "Create file for static rules #{static_rules}"
              say "* * * * * * * * * * * * * * * * * * * * * * * *\n"
              say "* You can write predefined rules to this file.\n"
              say "* This file will be concat with rules \n"
              say "* See 'iptables-save' format.\n"
              say "* * * * * * * * * * * * * * * * * * * * * * * * \n"

              if File.exist?(static_rules) && !options.force
                say 'File already exist!'
              else
                File.write static_rules, <<STATIC_RULES
*filter
-A INPUT -i lo -j ACCEPT
-A FORWARD -i lo -j ACCEPT
-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
-A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
COMMIT
STATIC_RULES
              end
            end
          end
        end
      end
    end
  end
end
