module IptablesWeb
  module Model
    class Node < Base
      self.element_name = 'node'
      self.include_root_in_json = true

      def self.handshake
        node = find('current')
        node.ips = []
        ::System.get_ifaddrs.each do |interface, config|
          next if interface.to_s.include?('lo')
          node.ips.push({
            interface: interface,
            ip: config[:inet_addr],
            netmask: config[:netmask]
          })
        end
        node.ips.uniq! { |ip| ip[:ip] }
        node.hostname = `hostname -f`
        if node.save && block_given?
          yield
        end
      end
    end
  end
end
