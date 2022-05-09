#!/usr/bin/python3
# -*- coding: utf-8 -*-
#
# Script to automatically process all simquality test result directories
# and generate a score file.
#
# Script is expected to be run from within the 'data' directory.

import os
import sys

import pandas as pd
import plotly.graph_objects as go
import csv

from typing import Dict
from PrintFuncs import *
from ProcessDirectory import processDirectory, CaseResults
from TSVContainer import TSVContainer
from dataclasses import dataclass

@dataclass
class SimQualityData:
    name: str
    testCaseDescription: str

    caseEvaluationResults: []
    caseResultData: pd.DataFrame

def readWeightFactors():
    # read weight factors
    # CVRMSE	Daily Amplitude CVRMSE	MBE	RMSEIQR	MSE	NMBE	NRMSE	RMSE	RMSLE	R² coefficient determination	std dev
    try:
        weightFactorsTSV = TSVContainer()
        weightFactorsTSV.readAsStrings(os.path.join(os.getcwd(), "WeightFactors.tsv"))
    except RuntimeError as e:
        print(e)
        print(f"At least one weight factor has to be specified in 'WeightFactors.tsv'.")
        exit(1)

    weightFactors = dict()

    for i in range(len(weightFactorsTSV.data[0])):
        weightFactors[weightFactorsTSV.data[0][i]] = int(weightFactorsTSV.data[1][i])

    weightFactors['Sum'] = sum(map(int, weightFactorsTSV.data[1]))  # convert to int and then sum it up

    return weightFactors

def readVariables(testCaseDir, testCaseName):
    myDict = dict()
    path = os.path.join(testCaseDir, testCaseName, "Auswertung", "Ergebnisse", "EvaluationPeriods.tsv")
    with open(path, mode='r', encoding="utf-8") as infile:
        reader = csv.reader(infile, delimiter='\t')
        headers = next(reader)
        columns = dict()
        for row in reader:
            for (i, v) in enumerate(row):
                if i not in columns.keys():
                    columns[i] = []
                columns[i].append(v)

    return columns[0]

def listTestCaseDirectories(path):
    dirs = []
    # process all subdirectories of `AP4` (i.e. test cases)
    subdirs = os.listdir(path)

    # process all subdirectory starting with TF
    for sd in subdirs:
        if len(sd) > 4 and sd.startswith("TF"):
            # extract next two digits and try to convert to a number
            try:
                testCaseNumber = int(sd[2:3])
            except Exception:
                printError("Malformed directory name: {}".format(sd))
                continue
            dirs.append(sd)
    return dirs

def convertEvaluationResultsToDataframe(evalData):
    """

    :type evalData: List[CaseResults]
    """
    df = pd.DataFrame(['Variable', 'Tool', 'CVRMSE', 'Daily Amplitude CVRMSE', 'MBE', 'RMSEIQR', 'MSE',
            'NMBE', 'NRMSE', 'RMSE', 'RMSLE', 'R squared coeff determination', 'std dev', 'SimQ-Score',
            'SimQ-Einordnung'])
    # now read in all the reference files, collect the variable headers and write out the collective file
    for i, cr in enumerate(evalData):
        vals = dict()

        vals['Variable'] = cr.Variable
        vals['Tool'] = cr.ToolID
        for norm in cr.norms.keys():
            vals[norm] = cr.norms[norm]
        vals['SimQ-Score'] = cr.score
        vals['SimQ-Einordnung'] = cr.simQbadge

        dfAppend = pd.DataFrame([vals])

        df = pd.concat([df, dfAppend], ignore_index=True)

    return df

def readTestCaseDescriptionFile(testCaseDir, testCaseName):
    path = os.path.join(testCaseDir, testCaseName, "TestCaseDescription.txt")
    with open(path, encoding="utf-8") as f:
        lines = f.read().replace("\n", "")

    return str(lines)


def analyseTestCase(path, testCase, variable) -> dict:
    # initialize colored console output
    init()

    weightFactors = readWeightFactors()
    sqd = SimQualityData(testCase, "", dict(), dict())

    # process all subdirectories of `AP4` (i.e. test cases)
    subdirs = os.listdir(path)

    if testCase not in subdirs:
        raise Exception(f"No TestCase Results Folder {testCase} does exist.")

    if 4 < len(testCase) and testCase.startswith("TF"):
        # extract next two digits and try to convert to a number
        try:
            testCaseNumber = int(testCase[2:3])
        except:
            raise Exception("Malformed test case name: {}".format(testCase))

    printNotification("\n################################################\n")
    printNotification("Processing directory '{}'".format(testCase))

    evaluationResults = processDirectory(os.path.join(path, testCase), variable, weightFactors)

    # covert all data to pandas data frame
    sqd.caseEvaluationResults = convertEvaluationResultsToDataframe(evaluationResults)

    # we also want to create some plotly charts
    # there fore we create a new data frame
    crd = sqd.caseResultData

    # skip test cases with missing/invalid 'Reference.tsv'
    if evaluationResults is None:
        raise Exception("No Test Case Data.")
    for cr in evaluationResults:
        if cr.Variable not in crd.keys():
            printNotification(f"Create new data frame.")
            crd[cr.Variable] = cr.timeDf
            # add reference results in first round
            crd[cr.Variable]['Reference'] = cr.referenceDf.loc[:, 'Data']

        crd[cr.Variable][cr.ToolID] = cr.toolDataDf.loc[:, 'Data']

    printNotification("\n################################################\n")
    printNotification("Done.")

    return sqd


# ---*** main ***---
if __name__ == "__main__":
    # testCaseDataDfs = scoreCalculation("./test_data", True)
    exit(0)
