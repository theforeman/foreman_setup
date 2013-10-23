Rails.application.routes.draw do
  namespace :foreman_setup do
    resources :provisioners, :except => [:edit, :update] do
      member do
        get 'step2'
        put 'step2_update'
        get 'step3'
      end
    end
  end
end
