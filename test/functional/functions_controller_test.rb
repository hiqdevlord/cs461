require 'test_helper'

class FunctionsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:functions)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create function" do
    assert_difference('Function.count') do
      post :create, :function => { }
    end

    assert_redirected_to function_path(assigns(:function))
  end

  test "should show function" do
    get :show, :id => functions(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => functions(:one).id
    assert_response :success
  end

  test "should update function" do
    put :update, :id => functions(:one).id, :function => { }
    assert_redirected_to function_path(assigns(:function))
  end

  test "should destroy function" do
    assert_difference('Function.count', -1) do
      delete :destroy, :id => functions(:one).id
    end

    assert_redirected_to functions_path
  end
end
