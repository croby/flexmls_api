require './spec/spec_helper'

# Test out the faraday connection stack.
describe FlexmlsApi do
  describe "FlexmlsMiddleware" do
    before(:all) do
      stubs = Faraday::Adapter::Test::Stubs.new do |stub|
        stub.post('/session') { [200, {}, '{"D": { 
            "Success": true,
            "Results": [{
                "AuthToken": "xxxxx",
                "Expires": "2010-10-30T15:49:01-05:00",
                "Roles": ["idx"] 
                }]
          }}'] 
        }
        stub.get('/system') { [200, {}, '{"D": {
          "Success": true, 
          "Results": [{
            "Name": "My User", 
            "OfficeId": "20070830184014994915000000", 
            "Configuration": [], 
            "Id": "20101202170654111629000000", 
            "MlsId": "20000426143505724628000000", 
            "Office": "test office", 
            "Mls": "flexmls Web Demonstration Database"
          }]}
          }'] 
        }
        stub.get('/expired') { [401, {}, fixture('errors/expired.json')] 
        }
        stub.get('/methodnotallowed') { [405, {}, '{"D": { 
            "Success": false,
            "Message": "Method Not Allowed",
            "Code": "1234"            
          }}'] 
        }
        stub.get('/epicfail') { [500, {}, '{"D": { 
            "Success": false,
            "Message": "EPIC FAIL",
            "Code": "0000"            
          }}'] 
        }
        stub.get('/unknownerror') { [499, {}, '{"D": { 
            "Success": false,
            "Message": "Some random status error",
            "Code": "0000"
          }}'] 
        }
        stub.get('/invalidjson') { [200, {}, '{"OMG": "THIS IS NOT THE API JSON THAT I KNOW AND <3!!!"}'] }
        stub.get('/garbage') { [200, {}, 'THIS IS TOTAL GARBAGE!'] }
      end

      @connection = test_connection(stubs)

    end
    
    it "should raised exception when token is expired" do
      expect { @connection.get('/expired')}.to raise_error(FlexmlsApi::PermissionDenied){ |e| e.code.should == FlexmlsApi::ResponseCodes::SESSION_TOKEN_EXPIRED }
    end

    it "should raised exception on error" do
      expect { @connection.get('/methodnotallowed')}.to raise_error(FlexmlsApi::NotAllowed){ |e| e.message.should == "Method Not Allowed" }
      expect { @connection.get('/epicfail')}.to raise_error(FlexmlsApi::ClientError){ |e| e.status.should be(500) }
      expect { @connection.get('/unknownerror')}.to raise_error(FlexmlsApi::ClientError){ |e| e.status.should be(499) }
    end

    it "should raised exception on invalid responses" do
      expect { @connection.get('/invalidjson')}.to raise_error(FlexmlsApi::InvalidResponse)
      # This should be caught in the request code
      expect { @connection.get('/garbage')}.to raise_error(MultiJson::DecodeError)
    end

    it "should give me a session response" do
      response = @connection.post('/session').body
      response.success.should eq(true)
      session = FlexmlsApi::Authentication::Session.new(response.results[0])
      session.auth_token.should eq("xxxxx")
    end
    
    it "should give me an api response" do
      response = @connection.get('/system').body
      response.success.should eq(true)
      response.results.length.should be > 0 
    end
    
  end
  
end

