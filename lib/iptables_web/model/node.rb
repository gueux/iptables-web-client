module IptablesWeb
  module Model
    class Node < Base
      self.element_name = 'node'
      self.include_root_in_json = true

      def self.handshake(dry_run = false, &block)
        node = find('current')
        if node
          begin
            block.call if block
          rescue Exception => e
            node.has_errors = true
            node.report = 'Exception: ' + e.message
            node.report << "\n"
            node.report << 'Backtrace: ' + e.backtrace.join("\n")
            raise e
          ensure
            return if dry_run
            puts ''
            # save node after updating
            node.ips = []
            ::System.get_ifaddrs.each do |interface, config|
              next if interface.to_s.include?('lo')
              node.ips.push({
                interface: interface,
                ip: config[:inet_addr],
                netmask: config[:netmask]
              })
            end
            logged_say '*** Found interfaces!!! ***'
            logger_log(node.ips.inspect, ::Logger::DEBUG)
            node.ips.uniq! { |ip| ip[:ip] }
            logged_say '*** Unique interfaces!!! ***'
            logger_log(node.ips.inspect, ::Logger::DEBUG)
            node.hostname = `hostname -f`
            node.save
          end
        end
      end
    end
  end
end
