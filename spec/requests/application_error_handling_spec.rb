require "rails_helper"

RSpec.describe "ApplicationController error handling", type: :request do
  before do
    stub_const("TestErrorsController", Class.new(ApplicationController) do
      def not_found
        raise NotFoundError, "widget not found"
      end

      def conflict
        raise ConflictError.new("already assigned", code: "already_assigned")
      end

      def bad_request
        params.require(:required_field)
      end

      def boom
        raise ArgumentError, "unexpected"
      end
    end)
  end

  around do |example|
    with_routing do |routes|
      routes.draw do
        get "/test_errors/not_found", to: "test_errors#not_found"
        get "/test_errors/conflict", to: "test_errors#conflict"
        get "/test_errors/bad_request", to: "test_errors#bad_request"
        get "/test_errors/boom", to: "test_errors#boom"
      end
      example.run
    end
  end

  it "renders ApplicationError subclasses with their own code and status" do
    get "/test_errors/not_found"

    expect(response).to have_http_status(:not_found)
    body = JSON.parse(response.body)
    expect(body["error"]["code"]).to eq("not_found")
    expect(body["error"]["request_id"]).to be_present
  end

  it "renders a custom code for a ConflictError" do
    get "/test_errors/conflict"

    expect(response).to have_http_status(:conflict)
    expect(JSON.parse(response.body)["error"]["code"]).to eq("already_assigned")
  end

  it "renders 400 when a required parameter is missing" do
    get "/test_errors/bad_request"

    expect(response).to have_http_status(:bad_request)
    expect(JSON.parse(response.body)["error"]["code"]).to eq("bad_request")
  end

  it "hides internal error details behind a generic 500 outside local environments" do
    allow(Rails.env).to receive(:local?).and_return(false)

    get "/test_errors/boom"

    expect(response).to have_http_status(:internal_server_error)
    body = JSON.parse(response.body)
    expect(body["error"]["code"]).to eq("internal_error")
    expect(body["error"]["message"]).not_to include("unexpected")
  end
end
