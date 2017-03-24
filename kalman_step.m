function T = kalman_step(T, frame)
% KALMAN_STEP - a single iteration of the Kalman filter.
%
% NOTE: This function is intended to be run as a TRACKER in the
% tracking framework.  See documentation for RUN_TRACKER.
%
% KALMAN_STEP(T, frame) takes the current frame image in 'frame',
% extracts the parameters of the Kalman filter from T.tracker, the
% measurement from T.representer, and advances the Kalman filter
% estimation one step.
%
% Parameters used from T.representer:
%  T.representer.BoundingBox - the bounding box of the current target.
%
% Parameters used from T.tracker:
%  T.tracker.H  - system model
%  T.tracker.Q  - system noise
%  T.tracker.F  - measurement model
%  T.tracker.R  - measurement noise
% 
% Inputs:
%  T     - tracker state structure.
%  frame - image to process.
% 
% See also: run_tracker, kalman_tracker


% Get the current filter state.
K = T.tracker;

% Don't do anything unless we're initialized.
if isfield(K, 'm_k1k1') && isfield(T.representer, 'BoundingBox')

  % Get the current measurement out of the representer.
  z_k = T.representer.BoundingBox';
  
  % Project the state forward m_{k|k-1}.
  m_kk1 = K.F * K.m_k1k1;
  
  % Partial state covariance update.
  P_kk1 = K.Q + K.F * K.P_k1k1 * K.F';
  
  % Innovation is disparity in actual versus predicted measurement.
  innovation = z_k - K.H * m_kk1;
  
  % The new state covariance.
  S_k = K.H * P_kk1 * K.H' + K.R;
  
  % The Kalman gain.
  K_k = P_kk1 * K.H' * inv(S_k);
  
  % The new state prediction.
  m_kk = m_kk1 + K_k * innovation;
  
  % And the new state covariance.
  P_kk = P_kk1 - K_k * K.H * P_kk1;
  
  % Innovation covariance.
  K.innovation = 0.2 * sqrt(innovation' * innovation) + (0.8) ...
      * K.innovation;
  
  % And store the current filter state for next iteration.
  K.m_k1k1 = m_kk;
  K.P_k1k1 = P_kk;
else
  if isfield(T.representer, 'BoundingBox');
    K.m_k1k1 = T.representer.BoundingBox';
    K.P_k1k1 = eye(4);
  end
end

% Make sure we stuff the filter state back in.
T.tracker = K;

return