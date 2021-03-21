data {
  int<lower = 1> N; // data size
  int<lower = 1> N_routes; // number of unique routes
  int<lower = 1> N_days; // number of uniqute dates
  
  // assigning chunks of data to each day
  int<lower = 1, upper = N> day_first_idx [N_days];
  int<lower = 1, upper = N> day_last_idx [N_days];
  
  // duration, sample size, and route index for each observation
  vector [N] mean_duration;
  vector [N] trips;
  int<lower=1, upper = N_routes> route [N];
}

parameters {
  // average trip length before/after change
  real mu1;
  real mu2;
  
  // trip standard deviation before/after change
  real<lower = 0> sigma1;
  real<lower = 0> sigma2;
  
  // random effects by route
  vector[N_routes] Z;
  real<lower = 0> sigma_Z;
}

// SLOWER VERSION (quadratic in N_days)
// transformed parameters {
//   // initialize each log probability with uniform distribution
//   vector[N_days] lp = rep_vector(-log(N_days), N_days);
//   
//   // center the observed means at grand mean by removing random effects
//   vector [N] mean_duration_ctr = mean_duration - Z[route];
//   
//   // loop over each possible change-point
//   for (cp in 1:N_days){
//     // calculate log probability for each date
//     for (d in 1:N_days){
//       
//       // find rows associated with date
//       int start = day_first_idx[d];
//       int end = day_last_idx[d];
//       
//       // mean/scale dependent on whether change-point has passed
//       real mu = d < cp ? mu1 : mu2;
//       real sigma = d < cp ? sigma1 : sigma2;
//       
//       // add density of observed daily means to log probability
//       lp[cp] = lp[cp] + normal_lpdf(mean_duration_ctr[start:end]| mu, sigma ./ sqrt(trips[start:end]));
//     }
//   }
// }
      
// FASTER VERSION (linear in N_days)
transformed parameters {
  // initialize each log probability with uniform distribution
  vector[N_days] lp = rep_vector(-log(N_days), N_days);
  
  // center the observed means at grand mean by removing random effects
  vector [N] mean_duration_ctr = mean_duration - Z[route];
  
  // vectors to hold log probability under each scenario
  vector[N_days + 1] lp_pre;
  vector[N_days + 1] lp_post;
  lp_pre[1] = 0;
  lp_post[1] = 0;
  
  // calculate log probability for each date
  for (d in 1:N_days) {
    
    // find rows associated with date
    int start = day_first_idx[d];
    int end = day_last_idx[d];
    
    // add density of observed daily means to both log probabilities
    lp_pre[d + 1] = lp_pre[d] + normal_lpdf(mean_duration_ctr[start:end] | mu1, sigma1 ./ sqrt(trips[start:end]));
    lp_post[d + 1] = lp_post[d] + normal_lpdf(mean_duration_ctr[start:end] | mu2, sigma2 ./ sqrt(trips[start:end]));
  }
  
  lp = lp + 
    head(lp_pre, N_days) + //log probability up until each possible change-point
    (lp_post[N_days + 1] - head(lp_post, N_days)); //log probability after each possible change-point
}


model {
  // would expect rides to be around 15 minutes
  mu1 ~ normal(15, 5);
  mu2 ~ normal(15, 5);
  
  // half-normal prior on scale terms
  sigma1 ~ normal(0, 5);
  sigma2 ~ normal(0, 5);
  
  // tighter half-normal prior on random effects
  sigma_Z ~ normal(0, 3);
  Z ~ normal(0, sigma_Z);
  
  // include marginalized latent parameter in posterior
  target += log_sum_exp(lp);
} 

generated quantities {
  // sample change points from posterior simplex
  int<lower = 1, upper = N> cp_sim = categorical_rng(softmax(lp));
}

