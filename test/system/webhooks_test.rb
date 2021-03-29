require "application_system_test_case"

class WebhooksTest < ApplicationSystemTestCase
  setup do
    @webhook = webhooks(:one)
  end

  test "visiting the index" do
    visit webhooks_url
    assert_selector "h1", text: "Webhooks"
  end

  test "creating a Webhook" do
    visit webhooks_url
    click_on "New Webhook"

    fill_in "Api response", with: @webhook.api_response
    fill_in "Origin", with: @webhook.origin
    fill_in "Payload", with: @webhook.payload
    click_on "Create Webhook"

    assert_text "Webhook was successfully created"
    click_on "Back"
  end

  test "updating a Webhook" do
    visit webhooks_url
    click_on "Edit", match: :first

    fill_in "Api response", with: @webhook.api_response
    fill_in "Origin", with: @webhook.origin
    fill_in "Payload", with: @webhook.payload
    click_on "Update Webhook"

    assert_text "Webhook was successfully updated"
    click_on "Back"
  end

  test "destroying a Webhook" do
    visit webhooks_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Webhook was successfully destroyed"
  end
end
