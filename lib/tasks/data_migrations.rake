namespace :data_migrations do
  desc "Initialize Stripe customer ID for all users without one already"
  task initialize_stripe_customers: :environment do
    User.where(stripe_customer_id: nil).each do |user|
      puts "Initializing Stripe Customer for user #{user.email.split('@').first}@"
      user.initialize_stripe_customer
    end
  end

  desc "Add a billing plan for all users that don't already have one"
  task create_default_billing_plans: :environment do
    # todo: Grab the actual promised date/time here
    BETA_TESTERS_CUTOFF_DATE = "2016-11-01 08:00:00".to_time # October 1 through November 1, 2016, with 8 hours wiggle room

    User.where(selected_billing_plan_id: nil).each do |user|
      puts "Setting default billing plan for #{user.email.split('@').first}@"

      beta_testers_plan  = BillingPlan.find_by(stripe_plan_id: 'free-for-life')
      standard_free_tier = BillingPlan.find_by(stripe_plan_id: 'starter')

      if beta_testers_plan.nil? || standard_free_tier.nil?
        raise "Couldn't find one of the necessary plans for this task -- check for free-for-life and starter stripe plan IDs"
      end

      if user.created_at < BETA_TESTERS_CUTOFF_DATE
        # If the user was created before the free-for-life beta testers promo, give them that plan
        puts "\tAdding to BETA TESTERS plan."
        user.update(selected_billing_plan_id: beta_testers_plan.id)
      else
        # Otherwise, give the user the default free plan
        puts "\tAdding to FREE TIER plan."
        user.update(selected_billing_plan_id: standard_free_tier.id)
      end

      # Since no active subscriptions is equivalent to the free tier, there's no need to build Subscriptions for these users
    end
  end

  desc "Add bandwidth bonuses to billing plans"
  task billing_plan_bandwidths: :environment do
    puts "Updating bandwidths for all billing plans"
    BillingPlan.find_by(stripe_plan_id: 'starter').update(bonus_bandwidth_kb: 50_000)
    BillingPlan.find_by(stripe_plan_id: 'free-for-life').update(bonus_bandwidth_kb: 250_000)
    BillingPlan.find_by(stripe_plan_id: 'early-adopters').update(bonus_bandwidth_kb: 950_000)
    BillingPlan.find_by(stripe_plan_id: 'premium').update(bonus_bandwidth_kb: 950_000)
    puts "Done"
  end

  desc "Add bandwidth counts to existing users"
  task initialize_user_bandwidths: :environment do
    starter_id = BillingPlan.find_by(stripe_plan_id: 'starter').id
    beta_id = BillingPlan.find_by(stripe_plan_id: 'free-for-life').id
    premium_ids = [
      BillingPlan.find_by(stripe_plan_id: 'early-adopters').id,
      BillingPlan.find_by(stripe_plan_id: 'premium').id
    ]

    # Premium
    puts "Setting premium users to 1GB"
    puts User.where(selected_billing_plan_id: premium_ids).update_all(upload_bandwidth_kb: 1_000_000) # 1GB

    # Starter
    puts "Setting starter users to 50MB"
    puts User.where(selected_billing_plan_id: nil).update_all(upload_bandwidth_kb: 50_000) # 50MB
    puts User.where(selected_billing_plan_id: starter_id).update_all(upload_bandwidth_kb: 50_000) # 50MB

    # Beta
    puts "Setting beta users to 250MB"
    puts User.where(selected_billing_plan_id: beta_id).update_all(upload_bandwidth_kb: 250_000) # 250MB
  end
end