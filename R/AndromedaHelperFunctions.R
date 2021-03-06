# @file ffHelperFunctions.R
#
# Copyright 2020 Observational Health Data Sciences and Informatics
#
# This file is part of PatientLevelPrediction
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

limitCovariatesToPopulation <- function(covariateData, rowIds) {
  ParallelLogger::logInfo(paste0('Starting to limit covariate data to population...'))
  
  newCovariateData <- Andromeda::andromeda(covariateRef = covariateData$covariateRef,
                                           analysisRef = covariateData$analysisRef)
  newCovariateData$covariates <- covariateData$covariates %>% dplyr::filter(rowId %in% rowIds)
  class(newCovariateData) <- "CovariateData"
  ParallelLogger::logInfo(paste0('Finished limiting covariate data to population...'))
  return(newCovariateData)
}

# return prev of ffdf 
calculatePrevs <- function(plpData, population){
  #===========================
  # outcome prevs
  #===========================
  
  # add population to sqllite
  population <- tibble::as_tibble(population)
  plpData$covariateData$population <- population %>% dplyr::select(rowId, outcomeCount)
  
  outCount <- nrow(plpData$covariateData$population %>% dplyr::filter(outcomeCount == 1))
  nonOutCount <- nrow(plpData$covariateData$population %>% dplyr::filter(outcomeCount == 0))
  
  # join covariate with label
  prevs <- plpData$covariateData$covariates %>% dplyr::inner_join(plpData$covariateData$population) %>%
    dplyr::group_by(covariateId) %>% 
    dplyr::summarise(prev.out = 1.0*sum(outcomeCount==1, na.rm = TRUE)/outCount,
              prev.noout = 1.0*sum(outcomeCount==0, na.rm = TRUE)/nonOutCount) %>%
    dplyr::select(covariateId, prev.out, prev.noout)
  
  #clear up data
  ##plpData$covariateData$population <- NULL
  
  return(as.data.frame(prevs))
}

