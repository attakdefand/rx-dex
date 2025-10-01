//! Price oracle implementations for DEX
//!
//! This crate provides various price oracle implementations:
//! - Time-Weighted Average Price (TWAP)
//! - Volume-Weighted Average Price (VWAP)
//! - Median price from multiple sources
//! - Simple moving average

use serde::{Deserialize, Serialize};
use std::collections::VecDeque;

/// A price observation
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PriceObservation {
    /// Price value
    pub price: u64,
    /// Volume at this price
    pub volume: u64,
    /// Timestamp of observation
    pub timestamp: u64,
}

/// Time-Weighted Average Price oracle
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TwapOracle {
    /// Price observations
    observations: VecDeque<PriceObservation>,
    /// Maximum number of observations to keep
    max_observations: usize,
    /// Time window in seconds
    time_window: u64,
}

impl TwapOracle {
    /// Create a new TWAP oracle
    pub fn new(max_observations: usize, time_window: u64) -> Self {
        TwapOracle {
            observations: VecDeque::new(),
            max_observations,
            time_window,
        }
    }

    /// Add a new price observation
    pub fn add_observation(&mut self, price: u64, volume: u64, timestamp: u64) {
        self.observations.push_back(PriceObservation {
            price,
            volume,
            timestamp,
        });

        // Remove old observations outside the time window
        while let Some(front) = self.observations.front() {
            if timestamp - front.timestamp > self.time_window {
                self.observations.pop_front();
            } else {
                break;
            }
        }

        // Limit the number of observations
        while self.observations.len() > self.max_observations {
            self.observations.pop_front();
        }
    }

    /// Calculate the TWAP
    pub fn calculate_twap(&self) -> Option<u64> {
        if self.observations.is_empty() {
            return None;
        }

        let mut total_price_time = 0u128;
        let mut total_time = 0u128;

        let observations: Vec<&PriceObservation> = self.observations.iter().collect();
        
        for window in observations.windows(2) {
            let obs1 = window[0];
            let obs2 = window[1];
            
            let time_diff = obs2.timestamp - obs1.timestamp;
            let avg_price = (obs1.price + obs2.price) / 2;
            
            total_price_time += avg_price as u128 * time_diff as u128;
            total_time += time_diff as u128;
        }

        if total_time == 0 {
            // If we only have one observation, return its price
            self.observations.back().map(|obs| obs.price)
        } else {
            Some((total_price_time / total_time) as u64)
        }
    }
}

/// Volume-Weighted Average Price oracle
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VwapOracle {
    /// Price observations
    observations: VecDeque<PriceObservation>,
    /// Maximum number of observations to keep
    max_observations: usize,
    /// Time window in seconds
    time_window: u64,
}

impl VwapOracle {
    /// Create a new VWAP oracle
    pub fn new(max_observations: usize, time_window: u64) -> Self {
        VwapOracle {
            observations: VecDeque::new(),
            max_observations,
            time_window,
        }
    }

    /// Add a new price observation
    pub fn add_observation(&mut self, price: u64, volume: u64, timestamp: u64) {
        self.observations.push_back(PriceObservation {
            price,
            volume,
            timestamp,
        });

        // Remove old observations outside the time window
        while let Some(front) = self.observations.front() {
            if timestamp - front.timestamp > self.time_window {
                self.observations.pop_front();
            } else {
                break;
            }
        }

        // Limit the number of observations
        while self.observations.len() > self.max_observations {
            self.observations.pop_front();
        }
    }

    /// Calculate the VWAP
    pub fn calculate_vwap(&self) -> Option<u64> {
        if self.observations.is_empty() {
            return None;
        }

        let mut total_value = 0u128; // price * volume
        let mut total_volume = 0u128;

        for obs in &self.observations {
            total_value += obs.price as u128 * obs.volume as u128;
            total_volume += obs.volume as u128;
        }

        if total_volume == 0 {
            None
        } else {
            Some((total_value / total_volume) as u64)
        }
    }
}

/// Median price oracle from multiple sources
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MedianOracle {
    /// Price observations from different sources
    observations: VecDeque<u64>,
    /// Maximum number of observations to keep
    max_observations: usize,
}

impl MedianOracle {
    /// Create a new median oracle
    pub fn new(max_observations: usize) -> Self {
        MedianOracle {
            observations: VecDeque::new(),
            max_observations,
        }
    }

    /// Add a new price observation
    pub fn add_observation(&mut self, price: u64) {
        self.observations.push_back(price);

        // Limit the number of observations
        while self.observations.len() > self.max_observations {
            self.observations.pop_front();
        }
    }

    /// Calculate the median price
    pub fn calculate_median(&self) -> Option<u64> {
        if self.observations.is_empty() {
            return None;
        }

        let mut sorted: Vec<u64> = self.observations.iter().cloned().collect();
        sorted.sort_unstable();

        let len = sorted.len();
        if len % 2 == 0 {
            // Average of two middle values
            let mid1 = sorted[len / 2 - 1];
            let mid2 = sorted[len / 2];
            Some((mid1 + mid2) / 2)
        } else {
            // Middle value
            Some(sorted[len / 2])
        }
    }

    /// Filter outliers using standard deviation
    pub fn calculate_filtered_median(&self, std_dev_threshold: f64) -> Option<u64> {
        if self.observations.is_empty() {
            return None;
        }

        // Calculate mean
        let sum: u64 = self.observations.iter().sum();
        let mean = sum as f64 / self.observations.len() as f64;

        // Calculate standard deviation
        let variance: f64 = self.observations
            .iter()
            .map(|&price| {
                let diff = price as f64 - mean;
                diff * diff
            })
            .sum::<f64>() / self.observations.len() as f64;
        let std_dev = variance.sqrt();

        // Filter outliers
        let mut filtered: Vec<u64> = self.observations
            .iter()
            .filter(|&&price| {
                let diff = (price as f64 - mean).abs();
                diff <= std_dev_threshold * std_dev
            })
            .cloned()
            .collect();

        if filtered.is_empty() {
            return self.calculate_median();
        }

        // Calculate median of filtered values
        filtered.sort_unstable();
        let len = filtered.len();
        if len % 2 == 0 {
            // Average of two middle values
            let mid1 = filtered[len / 2 - 1];
            let mid2 = filtered[len / 2];
            Some((mid1 + mid2) / 2)
        } else {
            // Middle value
            Some(filtered[len / 2])
        }
    }
}

/// Simple moving average oracle
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SmaOracle {
    /// Price observations
    observations: VecDeque<u64>,
    /// Maximum number of observations to keep
    max_observations: usize,
}

impl SmaOracle {
    /// Create a new SMA oracle
    pub fn new(max_observations: usize) -> Self {
        SmaOracle {
            observations: VecDeque::new(),
            max_observations,
        }
    }

    /// Add a new price observation
    pub fn add_observation(&mut self, price: u64) {
        self.observations.push_back(price);

        // Limit the number of observations
        while self.observations.len() > self.max_observations {
            self.observations.pop_front();
        }
    }

    /// Calculate the simple moving average
    pub fn calculate_sma(&self) -> Option<u64> {
        if self.observations.is_empty() {
            return None;
        }

        let sum: u64 = self.observations.iter().sum();
        Some(sum / self.observations.len() as u64)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_twap_oracle() {
        let mut oracle = TwapOracle::new(100, 3600); // 1 hour window
        
        let now = 1000;
        oracle.add_observation(100, 10, now);
        oracle.add_observation(200, 20, now + 100);
        oracle.add_observation(150, 15, now + 200);
        
        let twap = oracle.calculate_twap();
        assert!(twap.is_some());
    }

    #[test]
    fn test_vwap_oracle() {
        let mut oracle = VwapOracle::new(100, 3600); // 1 hour window
        
        oracle.add_observation(100, 10, 1000);
        oracle.add_observation(200, 20, 1100);
        oracle.add_observation(150, 15, 1200);
        
        let vwap = oracle.calculate_vwap();
        assert!(vwap.is_some());
        // VWAP should be weighted toward the higher volume observations
        assert!(vwap.unwrap() > 150);
    }

    #[test]
    fn test_median_oracle() {
        let mut oracle = MedianOracle::new(100);
        
        oracle.add_observation(100);
        oracle.add_observation(200);
        oracle.add_observation(150);
        oracle.add_observation(175);
        oracle.add_observation(125);
        
        let median = oracle.calculate_median();
        assert_eq!(median, Some(150));
    }

    #[test]
    fn test_sma_oracle() {
        let mut oracle = SmaOracle::new(5);
        
        oracle.add_observation(100);
        oracle.add_observation(200);
        oracle.add_observation(150);
        
        let sma = oracle.calculate_sma();
        assert_eq!(sma, Some(150)); // (100 + 200 + 150) / 3 = 150
    }
}