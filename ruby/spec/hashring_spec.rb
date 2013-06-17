require 'spec_helper'

module GameMachine
  describe Hashring do

    let(:servers) {['server1','server2']}
    let(:bucket_name) {'test_bucket'}
    subject do
      Hashring.new(servers,bucket_name)
    end

    describe "#server_for" do

      it "send a query" do
        test = '123'
        Dbquery.update('test') do |result|
          puts "QUERY = #{result} test=#{test}"
        end
      end
      it "returns server for value" do
        puts subject.server_for('test')
      end
    end
  end
end