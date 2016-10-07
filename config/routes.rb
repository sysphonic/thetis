Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  get 'rss/rss' => 'feeds#index'
  root :to => 'frames#index'
  match '/:controller(/:action)', via: [:get, :post]
end
