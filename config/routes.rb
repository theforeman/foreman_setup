Rails.application.routes.draw do
  namespace :foreman_setup do
    resources :provisioners, :except => [:edit, :update] do
      member do
        get 'edit', :to => :step2
        get 'step2'
        put 'step2_update'
        get 'step3'
        post 'step4'
        put 'step4_update'
        get 'step5'
      end
    end
  end
end
