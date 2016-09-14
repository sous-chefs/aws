module Opscode
  module Aws
    module Helpers
      include Opscode::Aws::Ec2
      def instance_tags
        if @instance_tags.nil?
          @instance_tags = {}
          ec2.describe_tags(filters: [{ name: 'resource-id', values: [instance_id] }])[:tags].map do |tag|
            @instance_tags[tag[:key]] = tag[:value]
          end
        end
        @instance_tags
      end
    end
  end
end
