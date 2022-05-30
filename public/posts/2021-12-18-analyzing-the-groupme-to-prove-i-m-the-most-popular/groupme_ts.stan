data {
  int T;
  int D;
  
  int K_yr;
  int<lower = 1, upper = 7> wday [T];
  
  int<lower = 0> msgs [T];
  
  vector[T] idx;
  matrix[D, T] B;
}

parameters {
  real<lower = 0, upper = 1> theta;
  row_vector[D] a_raw; 
  real<lower = 0> sigma; 
  real<lower = 0> tau; 
  
  vector[K_yr] alpha_yr;
  vector[K_yr] gamma_yr;
  
  vector[6] b_wday_raw;
  
}

transformed parameters { 
  row_vector[D] a;
  vector[T] Y_hat;
  vector[T] yr = rep_vector(0, T);
  vector[7] b_wday;
  
  for(k in 1:K_yr){
    yr += alpha_yr[k]*sin(2*pi()*k*idx/365.5) + gamma_yr[k]*cos(2*pi()*k*idx/365.5);
  }
  
  b_wday[1:6] = b_wday_raw;
  b_wday[7] = -sum(b_wday_raw);

  
  a = a_raw*tau;  
  
  Y_hat = to_vector(a*B)+ yr + b_wday[wday]; 
} 

model {
  a_raw ~ normal(0, 1); 
  tau ~ cauchy(0, 1); 
  sigma ~ cauchy(0, 1); 
  
  alpha_yr ~ normal(0, 1);
  gamma_yr ~ normal(0, 1);
  
  b_wday_raw ~ normal(0, 1);
  
  for(n in 1:T)
  if (msgs[n] == 0)
  1 ~ bernoulli(theta);
  else {
    0 ~ bernoulli(theta);
    msgs[n] ~ lognormal(Y_hat[n], sigma);
  }
  
} 
