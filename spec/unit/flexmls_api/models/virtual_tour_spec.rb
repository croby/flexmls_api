require './spec/spec_helper'

describe VirtualTour do
  before(:each) do
    @virtualtour = VirtualTour.new({
      :Uri => "http://www.flexmls.com/",
      :ResourceUri => "/v1/listings/20060712220814669202000000/virtualtours/20110105165843978012000000",
      :Name => "My Branded Tour",
      :Id => "20110105165843978012000000",
      :Type => "branded"
    })
  end

  it "should respond to a few methods" do
    VirtualTour.should respond_to(:find_by_listing_key)
    @virtualtour.should respond_to(:branded?)
    @virtualtour.should respond_to(:unbranded?)
  end

  it "should know if it's branded" do
    @virtualtour.branded?.should == true
    @virtualtour.unbranded?.should == false
  end

  it "should get virtual tours for a listing" do
    stub_auth_request
    stub_api_get('/listings/1234/virtualtours','listings/virtual_tours_index.json')

    v = VirtualTour.find_by_listing_key('1234')
    v.should be_an(Array)
    v.length.should == 5
  end



  after(:each) do
    @virtualtour = nil
  end

end
