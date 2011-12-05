require 'spec_helper'

describe UsersController do
  render_views

  describe "GET 'index'" do
    describe "for non-signed-in users" do
      it "should deny access " do
        get :index
        response.should redirect_to(signin_path)
      end
    end

    describe "for signed in users" do

      before(:each) do
        @user = test_sign_in(Factory(:user))
        Factory(:user, :email => "das@tan.com")
        Factory(:user, :email => "das@tan.kg")
        Factory(:user, :email => "das@tan.ru")
        Factory(:user, :email => "das@tan.net")

        30.times do
          Factory(:user, :email => Factory.next(:email))
        end
      end

      it "should be successful" do
        get :index
        response.should be_success
      end

      it "should have a right title" do
        get :index
        response.should have_selector("title", :content => "All users")
      end

      it "should have an element for each user" do
        get :index
        User.paginate(:page => 1).each do |user|
          response.should have_selector("li", :content => user.name)
        end
      end

      it "should paginate the users" do
        get :index
        response.should have_selector("div.pagination")
        response.should have_selector('span.disabled', :content => "Previous")
        response.should have_selector('a', :href => "/users?page=2", :content => "2")
        response.should have_selector('a', :href => "/users?page=2", :content => "Next")
      end
    end
  end

  describe "GET 'show'" do
    before(:each) do
      @user = Factory(:user)
    end

    it "should be successful" do
      get :show, :id => @user
      response.should be_success
    end

    it "should find the right user" do
      get :show, :id => @user
      assigns(:user).should == @user
    end

    it "should have a right title" do
      get :show, :id => @user
      response.should have_selector("title", :content => @user.name)
    end

    it "should have the user's name" do
      get :show, :id => @user
      response.should have_selector('h1', :content => @user.name)
    end

    it "should have a profile image" do
      get :show, :id => @user
      response.should have_selector('h1>img', :class => "gravatar")
    end

    it "should have the right URL" do
      get :show, :id => @user
      response.should have_selector("td>a", :content => user_path(@user),
                                    :href => user_path(@user))
    end
  end

  describe "GET 'new'" do
    it "returns http success" do
      get :new
      response.should be_success
    end

    it "should have a right title" do
      get :new
      response.should have_selector("title", :content => "Sign up")
    end
  end

  describe "POST 'create'" do

    describe "failure" do
      before(:each) do
        @attr = {:name => "", :email => "", :password => "", :password_confirmation => ""}
      end

      it "should have a right title" do
        post :create, :user => @attr
        response.should have_selector("title", :content => "Sign up")
      end

      it "should render a 'new' page" do
        post :create, :user => @attr
        response.should render_template('new')
      end

      it "should not create a user" do
        lambda do
          post :create, :user => @attr
        end.should_not change(User, :count)
      end
    end
  end

  describe "GET 'edit'" do
    before(:each) do
      @user = Factory(:user)
      test_sign_in(@user)
    end

    it "should be successful" do
      get :edit, :id => @user
      response.should be_success
    end

    it "should have a right title" do
      get :edit, :id => @user
      response.should have_selector("title", :content => "Edit user")
    end

    it "should have a link to change a gravatar" do
      get :edit, :id => @user
      response.should have_selector("a",
                                    :href => "http://gravatar.com/emails",
                                    :content => "change")
    end
  end

  describe "PUT 'update'" do

    before(:each) do
      @user = Factory(:user)
      test_sign_in(@user)
    end

    describe "failure" do
      before(:each) do
        @attr = {:name => "", :email => "", :password => "", :password_confirmation => ""}
      end

      it "should render the 'edit' page" do
        put :update, :id => @user, :user => @attr
        response.should render_template('edit')
      end

      it "should have a right title" do
        put :edit, :id => @user, :user => @attr
        response.should have_selector("title", :content => "Edit user")
      end
    end

    describe "success" do

      before(:each) do
        @attr = {:name => "Das Tan", :email => "das@tan.com", :password => "dastanko", :password_confirmation => "dastanko"}
      end

      it "should change the user's attribute '" do
        put :update, :id => @user, :user => @attr
        user = assigns(:user)
        @user.reload
        @user.name.should == user.name
        @user.email.should == user.email
        @user.encrypted_password.should == user.encrypted_password
      end

      it "should have a success flash message" do
        put :update, :id => @user, :user => @attr
        flash[:success].should =~ /updated/i
      end
    end
  end


  describe "success" do
    before(:each) do
      @attr = {:name => "Dastan Kojomuratov", :email => "dastanko_89@namba.kg",
               :password => "dastan",
               :password_confirmation => "dastan"}
    end

    it "should have a welcome message" do
      post :create, :user => @attr
      flash[:success].should =~ /welcome to the sample app/i
    end

    it "should redirect to a user 'show' page" do
      post :create, :user => @attr
      response.should redirect_to(user_path(assigns(:user)))
    end

    it "should create a user" do
      lambda do
        post :create, :user => @attr
      end.should change(User, :count).by(1)
    end

    it "should sign the user in" do
      post :create, :user => @attr
      controller.should be_signed_in
    end
  end
  describe "authentication of edit/update actions" do

    before(:each) do
      @user = Factory(:user)
    end
    describe "for non-signed in users" do

      it "should deny access to 'edit'" do
        get :edit, :id => @user
        response.should redirect_to(signin_path)
        flash[:notice].should =~ /sign in/
      end

      it "should deny access to 'update'" do
        put :update, :id => @user, :user => {}
        response.should redirect_to(signin_path)
        flash[:notice].should =~ /sign in/
      end
    end

    describe "for signed in users" do
      before(:each) do
        wrong_user = Factory(:user, :email => "das@tan.com")
        test_sign_in(wrong_user)
      end

      it "should require matching users for 'edit'" do
        get :edit, :id => @user
        response.should redirect_to(root_path)
      end

      it "should require matching users for 'update'" do
        put :update, :id => @user, :user => {}
        response.should redirect_to(root_path)
      end
    end
  end
end
