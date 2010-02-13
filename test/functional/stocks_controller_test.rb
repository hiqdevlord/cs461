require 'test_helper'

class StocksControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:stocks)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create stock" do
    assert_difference('Stock.count') do
      post :create, :stock => { }
    end

    assert_redirected_to stock_path(assigns(:stock))
  end

  test "should show stock" do
    get :show, :id => stocks(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => stocks(:one).id
    assert_response :success
  end

  test "should update stock" do
    put :update, :id => stocks(:one).id, :stock => { }
    assert_redirected_to stock_path(assigns(:stock))
  end

  test "should destroy stock" do
    assert_difference('Stock.count', -1) do
      delete :destroy, :id => stocks(:one).id
    end

    assert_redirected_to stocks_path
  end
end
