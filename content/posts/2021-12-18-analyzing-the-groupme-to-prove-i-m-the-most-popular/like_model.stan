data {
  int<lower=0> N;
  int<lower=0> msgs [N];
  int<lower=0> likes [N];
  
  int N_group;
  int<lower = 1, upper = N_group> sender [N];
  int<lower = 1, upper = N_group> liker[N];
  int<lower = 1, upper = N_group*N_group - N_group> combo [N];
  
}
parameters {
  real delta;
  vector [N_group - 1] alpha_raw;
  vector [N_group - 1] beta_raw;
  vector [N_group*N_group - N_group] gamma_raw ;
  real<lower=0> sigma;
}
transformed parameters {
  vector [N] logodds;
  vector [N_group] alpha;
  vector [N_group] beta;
  vector [N_group*N_group - N_group] gamma;
  
  alpha[1:(N_group-1)] = alpha_raw;
  alpha[N_group] = -sum(alpha_raw);
  
  beta[1:(N_group-1)] = beta_raw;
  beta[N_group] = -sum(beta_raw);
  
  gamma = gamma_raw*sigma;
  
  logodds = delta + alpha[sender] + beta[liker] + gamma[combo];
}
model {
  
  delta ~ normal(0, 3);
  alpha_raw ~ normal(0, 3);
  beta_raw ~ normal(0, 3);
  gamma_raw ~ normal(0, 1);
  sigma ~ exponential(1);
  
  likes ~ binomial_logit(msgs, logodds);
}