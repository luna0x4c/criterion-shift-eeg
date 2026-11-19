#!/usr/bin/env python
# -*- coding: utf-8 -*-


# FUTURE PLANS:
# jitter presentation times / feedback delay

"""
This experiment was created using PsychoPy3 Experiment Builder (v2023.2.2),
    on Thu Jul 25 22:31:39 2024
If you publish work using this script the most relevant publication is:

    Peirce J, Gray JR, Simpson S, MacAskill M, Höchenberger R, Sogo H, Kastman E, Lindeløv JK. (2019) 
        PsychoPy2: Experiments in behavior made easy Behav Res 51: 195. 
        https://doi.org/10.3758/s13428-018-01193-y

"""

# PROC OUTLINE:
# each study trial: 200ms blank, 200ms fixcross, 200ms blank, 1000ms img, no resp
# each test trial: 200ms blank1, 200ms fixcross, test img (max 5s), resp, 
#                   500ms feed (2s timeout message if no resp), 200ms blank2
# cond order: true feed >> false feed


# ========== trigger setup ==========

# MORE SPECIFIC TRIGGERS:

# same across all tasks
# 9 = instructions, 99 = space, 201 = pause [backspace], 202 = unpause [enter]

# TASK: PRACTICE, BASE (true feed), FALSE FEED, STRATEGIC, NO FEED
# PRACTICE:   study 1=blank,2=fixcross,3=img old
#             test  1=blank,2=fixcross,4/5=img old/new
#             resp  11,12,13=old low,med,high, 14,15,16=new lod,med,high
#                   10=no resp (there will be no trigger sent if no keypress)
#             feed  21=hit(old-correct-true),22=fa(old-incorrect-true),23=fa-FPF,
#                   24=cr(new-correct-true),25=miss(new-incorrect-true),26==miss-FPF,
#                   27=true no feed (not strategic), 28=strategic, 29=everything else where feed trigger was not updated 
#                   20=timeout/respond faster (trigger sent at timeout message onset)


# BASE: 30-60
# FALSE FEED 60-90
# STRATEGIC 90-120
# NO FEED +30- not currently run 



using_labjack = True  

# list of port addresses & trigger values
ports = list(range(6008,6016))
ports_alt = list(range(6808,6816))

bytes = [1,2,4,8,16,32,64,128]
byte = 0
port = 0
pos = 0

# function to get port address value based on specified trigger value
def get_trig(byte):
    pos = bytes.index(byte)
    port = ports[pos]
    return port


# --- Import packages ---
from psychopy import locale_setup
from psychopy import prefs
from psychopy import plugins
plugins.activatePlugins()
prefs.hardware['audioLib'] = 'ptb'
prefs.hardware['audioLatencyMode'] = '3'
from psychopy import sound, gui, visual, core, data, event, logging, clock, colors, layout, hardware, iohub, parallel
from psychopy.tools import environmenttools  # get this from 2022.2.4 source code
from psychopy.constants import (NOT_STARTED, STARTED, PLAYING, PAUSED,
                                STOPPED, FINISHED, PRESSED, RELEASED, FOREVER, priority)

import numpy as np  # whole numpy lib is available, prepend 'np.'
from numpy import (sin, cos, tan, log, log10, pi, average,
                   sqrt, std, deg2rad, rad2deg, linspace, asarray)
from numpy.random import random, randint, normal, shuffle, choice as randchoice
import os   # handy system and path functions
import sys  # to get file system encoding

import pandas as pd
import random

import psychopy.iohub as io
from psychopy.hardware import keyboard 
if using_labjack is True:
    from psychopy.hardware import labjacks
    p_port = labjacks.U3(debug=False)
    p_port.status = None   
    p_port.setData(int(0),address='EIO') # initialize port 
#from psychopy.hardware import labjacks  
#from psychopy.hardware.labjacks import U3
#import serial
import time 
import subprocess


# --- Setup global variables (available in all functions) ---
# ensure that relative paths start from the same directory as this script
_thisDir = os.path.dirname(os.path.abspath(__file__))
# store info about the experiment session
psychopyVersion = '2024.2.1'
expName = 'fpf_eeg'  


# ========== randomize exp params ==========
# strategic<>fpf task order 
task_order = ['strategic','false_feed']
random.shuffle(task_order)
print(f"Task order: {task_order}")

# test block lib/con order
strategic_cond_order = ['lib', 'con']
fpf_cond_order = ['lib', 'con']
random.shuffle(strategic_cond_order)
random.shuffle(fpf_cond_order)
print(f"Strategic task cond: {strategic_cond_order}")
print(f"FPF task cond: {fpf_cond_order}")

# strategic cue true/rev (flipped)
strat_cue_type = randchoice(['true', 'rev'])
flip_cond = {'lib': 'con', 'con': 'lib'}
print(f"Strategic cue: {strat_cue_type}")

# left-right keyboard orientation
keys_order = randchoice(['old-new', 'new-old'])
print(f"Keys: {keys_order}")

# set resp keys 
if keys_order == 'old-new':
    curr_old_keys = ['s', 'd', 'f']
    curr_new_keys = ['j', 'k', 'l']
    curr_old_key_list = 's d f'
    curr_new_key_list = 'j k l'
    left_label  = 'old'   # S D F
    right_label = 'new'   # J K L
    # set keyboard instructions
    resp_stim_text = 'Sure old  Maybe old  Unsure old  |  Unsure new  Maybe new  Sure new\n\n'\
                     '    S         D           F      |       J          K          L   '
    # strategic base rate / old/new percentage prompts
    lib_perc_text  = '           75% likely            >            25% likely           '
    con_perc_text  = '           25% likely            <            75% likely           '
else:
    curr_old_keys = ['j', 'k', 'l']
    curr_new_keys = ['s', 'd', 'f']
    curr_old_key_list = 'j k l'
    curr_new_key_list = 's d f'
    left_label  = 'new'   # S D F
    right_label = 'old'   # J K L
    # set keyboard instructions
    resp_stim_text = 'Sure new  Maybe new  Unsure new  |  Unsure old  Maybe old  Sure old\n\n'\
                     '    S         D           F      |       J          K          L   '
    # strategic base rate / old/new percentage prompts
    lib_perc_text  = '           25% likely            <            75% likely           '
    con_perc_text  = '           75% likely            >            25% likely           '

# pre-test instructions (same for both key orders; only the key labels change)
test_0_ins_text = 'Practice study phase finished! \n\n'\
                  'You will now begin the PRACTICE test phase. Remember, there could be any number of old or new images included during this test, and your task is to answer whether each image shown is old (appeared in the study phase) or new (did not appear in the study phase).\n\n'\
                  'Keys:\n'\
                  f'  S: certain/high confidence that it is {left_label}\n'\
                  f'  D: maybe/medium confidence that it is {left_label}\n'\
                  f'  F: unsure/low confidence that it is {left_label}  \n'\
                  f'  J: unsure/low confidence that it is {right_label}  \n'\
                  f'  K: maybe/medium confidence that it is {right_label}\n'\
                  f'  L: certain/high confidence that it is {right_label}\n'\
                  '\n\nPrepare by placing your left hand over S, D, F keys, and your right hand over J, K, L keys on the keyboard. During the test phase, make sure to answer as quickly and accurately as you can.\n\n'\
                  'Each trial has a time limit of 5 seconds.\n\nIf you have any questions about the instructions, ask the experimenter now.\n\nIf you are ready, press SPACE to start the test.\n\n'

test_1_ins_text = 'Study phase 1 finished! \n\nYou will now be tested on the images you just saw. The procedure will be exactly like the practice test. This test will NOT include any images from the practice.\n\nAgain, your task is to answer whether each image shown during this test was old or new (in the study phase or not), and how confident you are of your answer.\n\nPlease be sure to answer as quickly and accurately as you can, within 5 seconds.\n\nPlace your hands on the same keys as before.\n\n'

test_2_ins_text = 'Study phase 2 finished! \n\nYou will now be tested on the images you just saw. The procedure will still be the same, and this test will NOT include any images from previous tests.\n\nAgain, your task is to answer whether each image shown during this test was old or new (in the study phase or not), and how confident you are of your answer.\n\nPlease be sure to answer as quickly and accurately as you can, within 5 seconds.\n\nPlace your hands on the same position on the keyboard as before.\n\n'

test_3_ins_text = 'Study phase 3 finished! \n\nYou will now be tested on the images you just saw. The procedure will still be the same, and this test will NOT include any images from previous tests.\n\nAgain, your task is to answer whether each image shown during this test was old or new (in the study phase or not), and how confident you are of your answer.\n\nPlease be sure to answer as quickly and accurately as you can, within 5 seconds.\n\nPlace your hands on the same position on the keyboard as before.\n\n'

# study instructions text
study_0_ins_text='This is the PRACTICE study phase, to help you get to know the procedure. \n\nFor the sake of practice, you will only be seeing 5 images. Keep your eyes focused at the center of the screen, and do your best to remember all of the 5 images.\n\nWhen you are ready, press SPACE to begin. Images will appear on the screen immediately, so be ready.\n\n'
study_1_ins_text='You will now begin the FIRST real study phase. \nUnlike the practice phase, this block will contain a lot more images. You might not be able to remember every single one of them, but please do your best and remember as many as you can. \n\nA fixation cross will appear before each image. Try to keep your eyes focused at the center of the screen at all times.\n\nWhen you are ready, press SPACE to start this study phase.\n\n'
study_2_ins_text='You will now begin the SECOND study phase. The procedure will be the same as the previous study phase, but with a completely DIFFERENT set of materials, so you do not have to worry about accidentally misremembering something from the previous cycle.\n\nAgain, you might not be able to remember all of the images, but just do your best and remember as many as you can.\n\nTry to keep your eyes focused at the center of the screen at all times.\n\nWhen you are ready, press SPACE to begin.\n\n'
study_3_ins_text='You will now begin the THIRD and final study phase. The procedure will be exactly the same as before.\n\nAgain, the images in this study phase will be completely new. You might not be able to remember all of the images, just do your best and remember as many as you can.\n\nTry to keep your eyes focused at the center of the screen at all times.\n\nWhen you are ready, press SPACE to begin.\n\n'

welcome_msg_text = 'Welcome to the experiment! This is a visual memory study.\n\nDuring the study, you will view images of places and scenes (the study phase), and be tested on your memory of those images (the test phase).\n\n'\
                   'In the study phase, a series of images will appear on the screen. Use the fixation cross at the center of the screen to keep your eyes centered throughout the whole task. Please do your best to remember all the images presented.\n\n'\
                   'In the test phase, another set of images will appear, containing some images from the study phase (old images), and some new images, in random order. Your task is to indicate whether each of the test phase images is old or new (if it appeared in the study phase or not). You will also be asked to rate how confident you are in your judgment.\n\n'\
                   'You will undergo THREE rounds of study-test just like this.\n\n'\
                   'Do you have any questions about the instructions? If so, please ask the experimenter now.\n\nNext, you will start with a set of practice trials to help you become familiar with the procedure. The practice will not count toward your experiment data.\n\nIf you have finished reading and understand all the instructions above, please press the space bar to begin the practice.\n'


# information about this experiment
expInfo = {
    'participant': f"{randint(0, 999999):06.0f}",
    'session': '001',
    'date': data.getDateStr(),
    'subID': '',
    'subInitials': '',
    'numMonitor': 2,  # 1=laptop only, 2=chamber+laptop
    'debugging': 0,   # 1=yes=not plugged in, 0/blank=plugged in
    'expName': expName,
    'psychopyVersion': psychopyVersion,
}

def showExpInfoDlg(expInfo):
    """
    Show participant info dialog.
    Parameters
    ==========
    expInfo : dict
        Information about this experiment, created by the `setupExpInfo` function.
    
    Returns
    ==========
    dict
        Information about this experiment.
    """
    # temporarily remove keys which the dialog doesn't need to show
    poppedKeys = {
        'date': expInfo.pop('date', data.getDateStr()),
        'expName': expInfo.pop('expName', expName),
        'psychopyVersion': expInfo.pop('psychopyVersion', psychopyVersion),
    }
    # show participant info dialog
    dlg = gui.DlgFromDict(dictionary=expInfo, sortKeys=False, title=expName)
    if dlg.OK == False:
        core.quit()  # user pressed cancel
    # restore hidden keys
    expInfo.update(poppedKeys)
    # return expInfo
    return expInfo


def setupData(expInfo, dataDir=None):
    """
    Make an ExperimentHandler to handle trials and saving.
    
    Parameters
    ==========
    expInfo : dict
        Information about this experiment, created by the `setupExpInfo` function.
    dataDir : Path, str or None
        Folder to save the data to, leave as None to create a folder in the current directory.    
    Returns
    ==========
    psychopy.data.ExperimentHandler
        Handler object for this experiment, contains the data to save and information about 
        where to save it to.
    """

    # remove dialog-specific syntax from expInfo
    for key, val in expInfo.copy().items():
        newKey, _ = data.utils.parsePipeSyntax(key)
        expInfo[newKey] = expInfo.pop(key)
    
    # data file name stem = absolute path + name; later add .psyexp, .csv, .log, etc
    if dataDir is None:
        dataDir = _thisDir
    filename = u'data/%s_%s_%s' % (expInfo['participant'], expName, expInfo['date'])
    # make sure filename is relative to dataDir
    if os.path.isabs(filename):
        dataDir = os.path.commonprefix([dataDir, filename])
        filename = os.path.relpath(filename, dataDir)
    
    # an ExperimentHandler isn't essential but helps with data saving
    thisExp = data.ExperimentHandler(
        name=expName, version='',
        extraInfo=expInfo, runtimeInfo=None,
        originPath=None,
        savePickle=True, saveWideText=True,
        dataFileName=dataDir + os.sep + filename, sortColumns='alphabetical'
    )

    thisExp.setPriority('thisRow.t', priority.CRITICAL)
    thisExp.setPriority('expName', priority.LOW)

    # return experiment handler
    return thisExp


def setupLogging(filename):
    """
    Setup a log file and tell it what level to log at.
    
    Parameters
    ==========
    filename : str or pathlib.Path
        Filename to save log file and data files as, doesn't need an extension.
    
    Returns
    ==========
    psychopy.logging.LogFile
        Text stream to receive inputs from the logging system.
    """
    # this outputs to the screen, not a file
    logging.console.setLevel(logging.WARNING)
    # save a log file for detail verbose info
    logFile = logging.LogFile(filename+'.log', level=logging.WARNING)
    
    return logFile


def setupWindow(expInfo=None, win=None):
    """
    Setup the Window
    
    Parameters
    ==========
    expInfo : dict
        Information about this experiment, created by the `setupExpInfo` function.
    win : psychopy.visual.Window
        Window to setup - leave as None to create a new window.
    
    Returns
    ==========
    psychopy.visual.Window
        Window in which to run this experiment.
    """
    if win is None:
        # if not given a window to setup, make one
        displayIndex = expInfo['numMonitor']-1
        if displayIndex == 0:
            is_fullscreen = False
            monitorSize = [1024,768]
        else:
            is_fullscreen = True
            monitorSize = [1920,1080]
        win = visual.Window(
            # for screen, use display index (starts with 0) NOT screen number (starts with 1)
            # if numMonitor==1, win is on laptop screen, not fullscreen
            # if numMonitor==2, win is on second screen, is fullscreen
            # laptop monitor size is 1920/1080
            # chamber monitor size is ????
            size=monitorSize, fullscr=is_fullscreen, screen=displayIndex,
            winType='pyglet', allowStencil=False, 
            #monitor='testMonitor', 
            color=[0,0,0], colorSpace='rgb',
            blendMode='avg', useFBO=True, units='height', checkTiming=False  # we're going to do this ourselves in a moment
        )
        #if expInfo is not None:
            # store frame rate of monitor if we can measure it
        #    expInfo['frameRate'] = win.getActualFrameRate()
    else:
        # if we have a window, just set the attributes which are safe to set
        win.color = [0,0,0]
        win.colorSpace = 'rgb'
        win.backgroundImage = ''
        win.backgroundFit = 'none'
        win.units = 'height'
        win.winType='pyglet'
        win.checkTiming=False
        #win.recordFrameIntervals = True
    #win._monitorFrameRate = 60
    win.mouseVisible = False
    #win.hideMessage()         # not available in this version

    return win

# second monitoring window on laptop screen
win000 = visual.Window( 
    # always on laptop = display index 0 / screen number 1
    # always smaller window 800/600
    size=[800,600], fullscr=False, screen=0,
    winType='pyglet', allowStencil=False,
    color=[0,0,0], colorSpace='rgb',
    blendMode='avg', useFBO=True,
    units='height', checkTiming=False 
    )
win000._monitorFrameRate = 60
win000.mouseVisible = True
#win000.recordFrameIntervals = True


# --- Setup input devices ---
ioConfig = {}
ioSession = ioServer = eyetracker = None

# create a default keyboard (e.g. to check for escape)
defaultKeyboard = keyboard.Keyboard(backend='ptb')



def run(expInfo, thisExp, win, globalClock=None, thisSession=None):
    """
    Run the experiment flow.
    
    Parameter
    ==========
    expInfo : dict
        Information about this experiment, created by the `setupExpInfo` function.
    thisExp : psychopy.data.experiment.ExperimentHandler
        Handler object for this experiment, contains the data to save and information about 
        where to save it to.
    psychopy.visual.Window
        Window in which to run this experiment.
    globalClock : psychopy.core.clock.Clock or None
        Clock to get global time from - supply None to make a new one.
    thisSession : psychopy.session.Session or None
        Handle of the Session object this experiment is being run from, if any.
    """
    # mark experiment as started
    thisExp.status = STARTED
    # make sure variables created by exec are available globally
    exec = environmenttools.setExecEnvironment(globals())

    # make sure we're running in the directory for this experiment
    os.chdir(_thisDir)
    # get filename from ExperimentHandler for convenience
    filename = thisExp.dataFileName
    frameTolerance = 0.001  # how close to onset before 'same' frame
    endExpNow = False  # flag for 'escape' or other condition => quit the exp
    # get frame duration from frame rate in expInfo
    if 'frameRate' in expInfo and expInfo['frameRate'] is not None:
        frameDur = 1.0 / round(expInfo['frameRate'])
    else:
        frameDur = 1.0 / win.getActualFrameRate(infoMsg='')   # make 'measuring frame rate' message blank


    # ========== initialize devices ==========
    # if using_labjack is True:
    #     p_port = labjacks.U3(debug=False)
    #     p_port.status = None   
    #     p_port.setData(int(0),address='EIO') # initialize port 
    #     win.flip()
    # initialize port moved to beginning

    resp_real = keyboard.Keyboard(backend='ptb')

    def send_trigger(trig):
        p_port.setData(int(trig),address='EIO')
        core.wait(0.005)
        p_port.setData(int(0),address='EIO')


    # ==============================================     

    # ========== create stim lists ==========   

    # import & shuffle excel file
    excel_file = 'stim960.xlsx'
    df = pd.read_excel(excel_file)
    all_stim = df.iloc[:, 0].tolist()
    random.shuffle(all_stim)
    img_dict = 'stim_960'
    all_stim = [os.path.join(img_dict, img) for img in all_stim]
    
    # split lists 
    old_list_0 = all_stim[0:5]
    new_list_0 = all_stim[5:10]

    old_list_1 = all_stim[10:110]
    new_list_1 = all_stim[110:210]

    old_list_2 = all_stim[210:310]
    new_list_2 = all_stim[310:410]

    old_list_3 = all_stim[410:510]
    new_list_3 = all_stim[510:610]

    old_list_strat = all_stim[610:710]
    new_list_strat = all_stim[710:810]

    # combine & shuffle lists
    study_list_0 = old_list_0 
    test_list_0  = old_list_0 + new_list_0    
    random.shuffle(study_list_0)
    random.shuffle(test_list_0)

    random.shuffle(old_list_1)
    random.shuffle(new_list_1)  # shuffle study block items again
    study_list_1 = old_list_1 
    random.shuffle(study_list_1)

    random.shuffle(old_list_2)
    random.shuffle(new_list_2)
    study_list_2 = old_list_2 
    random.shuffle(study_list_2)

    random.shuffle(old_list_3)
    random.shuffle(new_list_3)
    study_list_3 = old_list_3 
    random.shuffle(study_list_3)

    random.shuffle(old_list_strat)
    random.shuffle(new_list_strat)
    study_list_strat = old_list_strat 
    random.shuffle(study_list_strat)

    old_list_1_1 = old_list_1[0:50]
    old_list_1_2 = old_list_1[50:100]

    old_list_2_1 = old_list_2[0:50]
    old_list_2_2 = old_list_2[50:100]

    old_list_3_1 = old_list_3[0:50]
    old_list_3_2 = old_list_3[50:100]

    old_list_strat_con = old_list_strat[0:25]
    old_list_strat_lib = old_list_strat[25:100]

    new_list_1_1 = new_list_1[0:50]
    new_list_1_2 = new_list_1[50:100]
    random.shuffle(new_list_1_1)
    random.shuffle(new_list_1_2)

    new_list_2_1 = new_list_2[0:50]
    new_list_2_2 = new_list_2[50:100]
    random.shuffle(new_list_2_1)
    random.shuffle(new_list_2_2)

    new_list_3_1 = new_list_3[0:50]
    new_list_3_2 = new_list_3[50:100]
    random.shuffle(new_list_3_1)
    random.shuffle(new_list_3_2)

    new_list_strat_con = new_list_strat[0:75]
    new_list_strat_lib = new_list_strat[75:100]
    random.shuffle(new_list_strat_con)
    random.shuffle(new_list_strat_lib)

    test_list_1_1 = old_list_1_1 + new_list_1_1
    test_list_1_2 = old_list_1_2 + new_list_1_2
    random.shuffle(test_list_1_1)
    random.shuffle(test_list_1_2)

    test_list_2_1 = old_list_2_1 + new_list_2_1
    test_list_2_2 = old_list_2_2 + new_list_2_2
    random.shuffle(test_list_2_1)
    random.shuffle(test_list_2_2)

    test_list_3_1 = old_list_3_1 + new_list_3_1
    test_list_3_2 = old_list_3_2 + new_list_3_2
    random.shuffle(test_list_3_1)
    random.shuffle(test_list_3_2)

    test_list_strat_con = old_list_strat_con + new_list_strat_con
    test_list_strat_lib = old_list_strat_lib + new_list_strat_lib
    random.shuffle(test_list_strat_con)
    random.shuffle(test_list_strat_lib)

    # prepare images as a list of dictionaries
    study_0_img = [{'stim_img': img} for img in study_list_0]
    test_0_img  = [{'stim_img': img} for img in test_list_0] 

    study_1_img = [{'stim_img': img} for img in study_list_1]
    test_1_img_1  = [{'stim_img': img} for img in test_list_1_1]
    test_1_img_2  = [{'stim_img': img} for img in test_list_1_2]
    
    study_2_img = [{'stim_img': img} for img in study_list_2]
    test_2_img_1  = [{'stim_img': img} for img in test_list_2_1]
    test_2_img_2  = [{'stim_img': img} for img in test_list_2_2]

    study_3_img = [{'stim_img': img} for img in study_list_3]
    test_3_img_1  = [{'stim_img': img} for img in test_list_3_1]
    test_3_img_2  = [{'stim_img': img} for img in test_list_3_2]

    study_strat_img = [{'stim_img': img} for img in study_list_strat]
    test_strat_img_con  = [{'stim_img': img} for img in test_list_strat_con]
    test_strat_img_lib  = [{'stim_img': img} for img in test_list_strat_lib]

    # ========== create img/text stim ==========
    # study/test img stimuli
    img = visual.ImageStim(
        win=win,image=None, mask=None, anchor='center',ori=0.0, pos=(0,0), 
        size=(0.5,0.5), color=[1,1,1], colorSpace='rgb',texRes=128.0, interpolate=True)
    img000 = visual.ImageStim(
        win=win000,image=None, mask=None, anchor='center',ori=0.0, pos=(0,0), 
        size=(0.5,0.5), color=[1,1,1], colorSpace='rgb',texRes=128.0, interpolate=True)
    
    # feedback text
    incorr_ans = visual.TextStim(win=win,text='Incorrect',font='UbuntuMono',pos=(0,0),height=0.05,color='#930725')
    incorr_ans000 = visual.TextStim(win=win000,text='Incorrect',font='UbuntuMono',pos=(0,0),height=0.05,color='#930725')
    
    corr_ans = visual.TextStim(win=win, text='Correct',font='UbuntuMono',pos=(0,0),height=0.05,color='#056817')
    corr_ans000 = visual.TextStim(win=win000, text='Correct',font='UbuntuMono',pos=(0,0),height=0.05,color='#056817')
    
    time_out = visual.TextStim(win=win, text='Please respond within 5 seconds.',font='UbuntuMono',pos=(0,0),height=0.05)
    time_out000 = visual.TextStim(win=win000, text='Please respond within 5 seconds.',font='UbuntuMono',pos=(0,0),height=0.05)
    
    blank_ans = visual.TextStim(win=win,text='')
    blank_ans000 = visual.TextStim(win=win000,text='')
    
    # resp prompt text
    resp_stim = visual.TextStim(win=win,text=resp_stim_text,pos=(0,-0.35),font='UbuntuMono',height=0.03)
    resp_stim000 = visual.TextStim(win=win000,text=resp_stim_text,pos=(0,-0.35),font='UbuntuMono',height=0.03)

    # strategic prompt text
    lib_perc_stim = visual.TextStim(win=win,text=lib_perc_text,pos=(0,-0.45),font='UbuntuMono',height=0.03)
    con_perc_stim = visual.TextStim(win=win,text=con_perc_text,pos=(0,-0.45),font='UbuntuMono',height=0.03)
    lib_perc_stim000 = visual.TextStim(win=win000,text=lib_perc_text,pos=(0,-0.45),font='UbuntuMono',height=0.03)
    con_perc_stim000 = visual.TextStim(win=win000,text=con_perc_text,pos=(0,-0.45),font='UbuntuMono',height=0.03)
    
    # ========== instructions & repeat stim ==========
    paused = visual.TextStim(win=win, text='-PAUSED-',font='UbuntuMono',pos=(0,0),height=0.05)
    paused_rect = visual.Rect(win=win,size=[0.7,0.7],fillColor=[0,0,0],lineColor=[1,1,1],pos=(0,0),units='height')
    paused000 = visual.TextStim(win=win000, text='-PAUSED-',font='UbuntuMono',pos=(0,0),height=0.05)
    paused_rect000 = visual.Rect(win=win000,size=[0.6,0.6],fillColor=[0,0,0],lineColor=[1,1,1],pos=(0,0),units='height')
    
    welcome_msg = visual.TextStim(win=win,text = welcome_msg_text,alignText='left',font='UbuntuMono',pos=(0,0),height=0.03)
    welcome_msg000 = visual.TextStim(win=win000,text = welcome_msg_text,alignText='left',font='UbuntuMono',pos=(0,0),height=0.03)
    
    study_0_ins = visual.TextStim(win=win,text=study_0_ins_text,alignText='left',font='UbuntuMono',height=0.03)
    study_0_ins000 = visual.TextStim(win=win000,text=study_0_ins_text,alignText='left',font='UbuntuMono',height=0.03)

    test_0_ins = visual.TextStim(win=win,text=test_0_ins_text,alignText='left',font='UbuntuMono',height=0.03)
    test_0_ins000 = visual.TextStim(win=win000,text=test_0_ins_text,alignText='left',font='UbuntuMono',height=0.03)

    study_1_ins = visual.TextStim(win=win,text=study_1_ins_text,alignText='left',font='UbuntuMono',height=0.03)
    study_1_ins000 = visual.TextStim(win=win000,text=study_1_ins_text,alignText='left',font='UbuntuMono',height=0.03)
    
    test_1_ins = visual.TextStim(win=win, text=test_1_ins_text,alignText='left',font='UbuntuMono',height=0.03)
    test_1_ins000 = visual.TextStim(win=win000, text=test_1_ins_text,alignText='left',font='UbuntuMono',height=0.03)
    
    study_2_ins = visual.TextStim(win=win,text=study_2_ins_text,alignText='left',font='UbuntuMono',height=0.03)
    study_2_ins000 = visual.TextStim(win=win000,text=study_2_ins_text,alignText='left',font='UbuntuMono',height=0.03)
    
    test_2_ins = visual.TextStim(win=win,text=test_2_ins_text,alignText='left',font='UbuntuMono',height=0.03)
    test_2_ins000 = visual.TextStim(win=win000,text=test_2_ins_text,alignText='left',font='UbuntuMono',height=0.03)
    
    study_3_ins = visual.TextStim(win=win,text=study_3_ins_text,alignText='left',font='UbuntuMono',height=0.03)
    study_3_ins000 = visual.TextStim(win=win000,text=study_3_ins_text,alignText='left',font='UbuntuMono',height=0.03)

    test_3_ins = visual.TextStim(win=win,text=test_3_ins_text,alignText='left',font='UbuntuMono',height=0.03)
    test_3_ins000 = visual.TextStim(win=win000,text=test_3_ins_text,alignText='left',font='UbuntuMono',height=0.03)

    # no block 4

    test_half_msg = visual.TextStim(win=win,text='You just finished the first half of this round. Take a break and rest your eyes!',alignText='left',font='UbuntuMono',height=0.03)
    test_half_msg000 = visual.TextStim(win=win000,text='You just finished the first half of this round. Take a break and rest your eyes!',alignText='left',font='UbuntuMono',height=0.03)
    
    end_msg = visual.TextStim(win=win, 
        text='This is the end of the study. Thank you for your participation! \n\nPlease press Space to exit the task. The experimenter will bring you out of the testing room.',
        alignText='left',font='UbuntuMono',height=0.03)
    end_msg000 = visual.TextStim(win=win000, 
        text='This is the end of the study. Thank you for your participation! \n\nPlease press Space to exit the task. The experimenter will bring you out of the testing room.',
        alignText='left',font='UbuntuMono',height=0.03)
    
    blank_stim = visual.TextStim(win=win,text=None,height=0.05)
    blank_stim000 = visual.TextStim(win=win000,text=None,height=0.05)
    
    cross_stim = visual.TextStim(win=win,text='+',font='UbuntuMono',height=0.05)
    cross_stim000 = visual.TextStim(win=win000,text='+',font='UbuntuMono',height=0.05)
        
    # create some handy timers
    
    # global clock to track the time since experiment started
    if globalClock is None:
        # create a clock if not given one
        globalClock = core.Clock()
    if isinstance(globalClock, str):
        # if given a string, make a clock accoridng to it
        if globalClock == 'float':
            # get timestamps as a simple value
            globalClock = core.Clock()    # this version does not support specifying format
        elif globalClock == 'iso':
            # get timestamps in ISO format
            globalClock = core.Clock(format='%Y-%m-%d_%H:%M:%S.%f%z')
        else:
            # get timestamps in a custom format
            globalClock = core.Clock(format=globalClock)
    if ioServer is not None:
       # ioServer.syncClock(globalClock)
        iohub.server.syncClock(globalClock)
    logging.setDefaultClock(globalClock)
    # routine timer to track time remaining of each (possibly non-slip) routine
    routineTimer = core.Clock()
    win.flip()  # flip window to reset last flip timer
    win000.flip()
    # store the exact time the global clock started
    expInfo['expStart'] = data.getDateStr(
        format='%Y-%m-%d %Hh%M.%S.%f %z', fractionalSecondDigits=1
    )


    # ===========================================================
    # ================== check for quit/pause ===================
    # ===========================================================

    # quit/pause check & save intermittently
    def checkForQuit(): 
        if defaultKeyboard.getKeys(keyList=["escape"]):
            # save when quit 
            thisExp.saveAsWideText(filename + '.csv', delim='auto')
            core.quit()
    
    def checkForPause(timer):
        checkForQuit()
        pauseKey=[]
        continueKey=[]
        paused_this_trial = False
        for pauseKey in event.getKeys():
            if pauseKey in ['backspace']:
                paused_this_trial = True
                # start pause clock
                thisPauseTimer = core.Clock()
                event.clearEvents()
                if using_labjack is True:
                    # mark pause in EEG data
                    stim_trigger = 201
                    win.callOnFlip(send_trigger,stim_trigger)
                break 

        if paused_this_trial is True:
            while thisPauseTimer.getTime() >= 0.000:
                checkForQuit()
                paused_rect.setAutoDraw(True)
                paused.setAutoDraw(True)
                win.flip()
                paused_rect000.setAutoDraw(True)
                paused000.setAutoDraw(True)
                win000.flip()

                for continueKey in event.getKeys():
                    if continueKey in ['return']:
                        event.clearEvents() 
                        if using_labjack is True:
                            # mark resume in EEG data
                            stim_trigger = 202
                            win.callOnFlip(send_trigger,stim_trigger)
                    break 
                if continueKey in ['return']:
                    break 

            paused_rect.setAutoDraw(False)
            paused.setAutoDraw(False)
            win.flip()
            paused_rect000.setAutoDraw(False)
            paused000.setAutoDraw(False)
            win000.flip()

            # how long trial has been paused 
            print(thisPauseTimer.getTime())
            # deduct paused time from routine timer 
            timer.addTime(-thisPauseTimer.getTime())

            # add pause timestamp 
            thisExp.addData('paused_this_trial',True)
            thisExp.addData('pause_durr',thisPauseTimer.getTime())
            event.clearEvents()

    # ======================================================================

    # ===========================================================
    # ====================== instructions =======================
    # ===========================================================
    def show_instructions(curr_block,curr_msg,curr_msg000): 

        #thisExp.timestampOnFlip(win, 'thisRow.tGlobal')
        thisExp.addData('thisRow.tGlobal',globalClock.getTime())

        # ==================== BLANK ============================
        # blank before stim 

        thisExp.addData('blank_start_1',globalClock.getTime())

        # send trigger
        if using_labjack is True: 
            stim_trigger = 1 + curr_block*30
            win.callOnFlip(send_trigger,stim_trigger)

        routineTimer = core.Clock()
        while routineTimer.getTime() < 0.200000:
            checkForPause(routineTimer)
            blank_stim.setAutoDraw(True)
            win.flip()
            blank_stim000.setAutoDraw(True)
            win000.flip()
    
        blank_stim.setAutoDraw(False)
        win.flip()
        blank_stim000.setAutoDraw(False)
        win000.flip()            
        thisExp.addData('blank_end_1',globalClock.getTime())

        # reset timer
        routineTimer.addTime(-0.200000)

        # ===================== INS =============================

        if using_labjack is True: 
            stim_trigger = 9
            win.callOnFlip(send_trigger,stim_trigger)
            win.flip()
            thisExp.addData('txt_port_start',globalClock.getTime())
            thisExp.addData('stim_trigger',stim_trigger)

        # add timestamp for img start
        thisExp.addData('txt_start',globalClock.getTime())
        #thisExp.addData('curr_framerate',win.getActualFrameRate(infoMsg=''))

        # ==================== RESP =============================

        # initialize keyresp
        resp_real.keys = []
        resp_real.rt = []
        keylist = ['space']
        keys = []
        
        insTimer = core.Clock()
        while insTimer.getTime() >= 0.000:
            checkForPause(insTimer)
            curr_msg.setAutoDraw(True)
            win.flip()
            curr_msg000.setAutoDraw(True)
            win000.flip()

            for keys in event.getKeys():
                if keys in keylist:
                    #print(keys)
                    event.clearEvents()
                break

            if len(keys)>0 and keys in keylist:
                break         

        curr_msg.setAutoDraw(False)
        win.flip()
        curr_msg000.setAutoDraw(False)
        win000.flip() 

        resp_real.keys = keys
        resp_real.rt = routineTimer.getTime()    

        # send resp trigger
        if using_labjack is True: 
            # instruction trigger [space=99]
            resp_trigger = 99
            win.callOnFlip(send_trigger,resp_trigger)
            win.flip()
            thisExp.addData('resp_port_send',globalClock.getTime())
            thisExp.addData('resp_trigger',resp_trigger)
            thisExp.addData('stim_port_end',globalClock.getTime())
        
        thisExp.addData('resp_real.key',resp_real.keys)
        thisExp.addData('resp_real.rt',resp_real.rt)
        thisExp.addData('txt_end',globalClock.getTime())

        # reset timer
        insTimer.reset()

        # flush keys
        event.clearEvents()

        # ==================== BLANK ============================
        # blank after resp & before next trial
        
        thisExp.addData('blank_start_2',globalClock.getTime())

        # send trigger
        if using_labjack is True: 
            stim_trigger = 1 + curr_block*30
            #win.callOnFlip(send_trigger,stim_trigger)

        routineTimer = core.Clock()
        while routineTimer.getTime() < 0.200000:
            checkForPause(routineTimer)
            blank_stim.setAutoDraw(True)
            win.flip()
            blank_stim000.setAutoDraw(True)
            win000.flip()
    
        blank_stim.setAutoDraw(False)
        win.flip()
        blank_stim000.setAutoDraw(False)
        win000.flip()            
        thisExp.addData('blank_end_2',globalClock.getTime())

        # reset timer
        routineTimer.addTime(-0.200000)
                            
        # next trial
        thisExp.nextEntry()






# ////////////////////////////////////////////////////////////////////////////////////

# COUNTDOWN 

# ////////////////////////////////////////////////////////////////////////////////////








    # ===========================================================
    # ======================== study trial ======================
    # ===========================================================

    def run_study_trials(curr_block,curr_list,curr_task):

        """
        routine for study trials:
            - 200ms blank, 200ms fixcross, 1s img
        """

        study_loop = data.TrialHandler(nReps=1.0, method='random', 
            extraInfo=expInfo, originPath=-1,
            trialList=curr_list, seed=None, name='study_loop')
    
        thisExp.addLoop(study_loop)  # add the loop to the experiment
        this_study_loop = study_loop.trialList[0]  # so we can initialise stimuli with some values
        
        # abbreviate parameter names if possible (e.g. rgb = thisstudy_loop.rgb)
        if this_study_loop != None:

            for paramName in this_study_loop:
                globals()[paramName] = this_study_loop[paramName]
    
        for this_study_loop in study_loop:

            currentLoop = study_loop

            #thisExp.timestampOnFlip(win, 'thisRow.tGlobal')
            thisExp.addData('thisRow.tGlobal',globalClock.getTime())
                        
            # ==================== BLANK =========================
            # blank before study stim (start of trial)

            thisExp.addData('blank_start_1',globalClock.getTime())

            # send trigger
            if using_labjack is True: 
                stim_trigger = 1 + 30*curr_block
                win.callOnFlip(send_trigger,stim_trigger)

            routineTimer = core.Clock()
            while routineTimer.getTime() < 0.200000:
                checkForPause(routineTimer)
                blank_stim.setAutoDraw(True)
                win.flip()
                blank_stim000.setAutoDraw(True)
                win000.flip()
        
            blank_stim.setAutoDraw(False)
            win.flip()
            blank_stim000.setAutoDraw(False)
            win000.flip()            
            thisExp.addData('blank_end_1',globalClock.getTime())

            # reset timer
            routineTimer.addTime(-0.200000)

            # ==================== FIXCROSS =======================

            thisExp.addData("fixcross_start",globalClock.getTime())

            # send trigger
            if using_labjack is True: 
                stim_trigger = 2 + curr_block*30
                win.callOnFlip(send_trigger,stim_trigger)

            while routineTimer.getTime() < 0.200000:
                checkForPause(routineTimer)
                cross_stim.setAutoDraw(True)
                win.flip()
                cross_stim000.setAutoDraw(True)
                win000.flip()
            
            cross_stim.setAutoDraw(False)
            win.flip()
            cross_stim000.setAutoDraw(False)
            win000.flip()
            thisExp.addData('fixcross_end',globalClock.getTime())

            # reset timer
            routineTimer.addTime(-0.200000)

            # ==================== STUDY IMG ======================

            # set & draw study image for current trial
            stim_img = this_study_loop['stim_img']
            img.setImage(stim_img)  # Get the image file path & set the image for the current trial
            img000.setImage(stim_img)  

            # add timestamp for img start
            thisExp.addData('img_start',globalClock.getTime())
            #thisExp.addData('curr_framerate',win.getActualFrameRate(infoMsg=''))

            # send trigger
            if using_labjack is True: 
                stim_trigger = 3 + curr_block*30
                win.callOnFlip(send_trigger,stim_trigger)
                #thisExp.addData('img_port_start',globalClock.getTime())
                thisExp.addData('stim_trigger',stim_trigger)

            while routineTimer.getTime() < 1.000:
                checkForPause(routineTimer)
                img.setAutoDraw(True)
                win.flip()
                img000.setAutoDraw(True)
                win000.flip()

            img.setAutoDraw(False)
            win.flip()
            img000.setAutoDraw(False)
            win000.flip()
            thisExp.addData('img_end',globalClock.getTime())

            # record other relevant info
            thisExp.addData('stim_routine', "study_img")
            thisExp.addData('stim', stim_img)
            thisExp.addData('studied', 1)
            thisExp.addData('task', curr_task)
            thisExp.addData('phase', "study")

            # reset timer
            routineTimer.addTime(-1.000)

            # next trial
            thisExp.nextEntry()


    # ===========================================================
    # ========================= test trial ======================
    # ===========================================================

    def run_test_trials(curr_block,curr_list,curr_task,n_cond,
                        curr_old_list,curr_new_list):
                
        # record stim, resp, feed trigger value
        # n_cond should be index 0 or 1 (NOT lib/con)
        
        if curr_task == "strategic":
            curr_cond = strategic_cond_order[n_cond]   # ON SCREEN cue
            if strat_cue_type == 'true':
                base_cond = curr_cond                  # REAL base rate
            elif strat_cue_type == 'rev':
                base_cond = flip_cond[curr_cond]
        elif curr_task == "false_feed":
            curr_cond = fpf_cond_order[n_cond]
            base_cond = curr_cond
        else:
            curr_cond = 'NONE'
            base_cond = 'NONE'          

        # set up handler to look after randomisation of conditions etc
        test_loop = data.TrialHandler(nReps=1.0, method='random', 
            extraInfo=expInfo, originPath=-1,
            trialList=curr_list, seed=None, name='test_loop')
        
        thisExp.addLoop(test_loop)  # add the loop to the experiment
        this_test_loop = test_loop.trialList[0]  # so we can initialise stimuli with some values
        
        # abbreviate parameter names if possible (e.g. rgb = this_test_loop.rgb)
        if this_test_loop != None:

            for paramName in this_test_loop:
                globals()[paramName] = this_test_loop[paramName]
        
        for this_test_loop in test_loop:

            # initialize real resp & feed vars
            ans_text_real = None
            ans_text = visual.TextStim(win=win,text='')
            ans_text000 = visual.TextStim(win=win000,text='')
            resp_type = None
            is_correct = 999
            studied = 999
            roll_fpf = None      # default none
            trial_is_fpf = None  # default none
            fpf_chance = 999
            feed_durr = 0.500 # default 0.5s

            currentLoop = test_loop
            #thisExp.timestampOnFlip(win, 'thisRow.tGlobal')
            thisExp.addData('thisRow.tGlobal',globalClock.getTime())
            
            # abbreviate parameter names if possible (e.g. rgb = this_test_loop.rgb)
            if this_test_loop != None:
                for paramName in this_test_loop:
                    globals()[paramName] = this_test_loop[paramName]

            # ==================== BLANK =========================
            # blank before test stim (start of trial)

            thisExp.addData('blank_start_1',globalClock.getTime())

            # send trigger
            if using_labjack is True: 
                stim_trigger = 1 + curr_block*30
                win.callOnFlip(send_trigger,stim_trigger)

            routineTimer = core.Clock()
            while routineTimer.getTime() < 0.200000:
                checkForPause(routineTimer)
                blank_stim.setAutoDraw(True)
                win.flip()
                blank_stim000.setAutoDraw(True)
                win000.flip()
        
            blank_stim.setAutoDraw(False)
            win.flip()
            blank_stim000.setAutoDraw(False)
            win000.flip()            
            thisExp.addData('blank_end_1',globalClock.getTime())

            # reset timer
            routineTimer.addTime(-0.200000)

            # =================== FIXCROSS ======================

            thisExp.addData("fixcross_start",globalClock.getTime())

            # send trigger
            if using_labjack is True: 
                stim_trigger = 2 + curr_block*30
                win.callOnFlip(send_trigger,stim_trigger)

            while routineTimer.getTime() < 0.200000:
                checkForPause(routineTimer)
                cross_stim.setAutoDraw(True)
                win.flip()
                cross_stim000.setAutoDraw(True)
                win000.flip()
            
            cross_stim.setAutoDraw(False)
            win.flip()
            cross_stim000.setAutoDraw(False)
            win000.flip()
            thisExp.addData('fixcross_end',globalClock.getTime())

            # reset timer
            routineTimer.addTime(-0.200000)

            # ================= TEST IMG ======================

            # set & draw test image for current trial
            stim_img = this_test_loop['stim_img']
            img.setImage(stim_img)  # Get the image file path & set the image for the current trial
            img000.setImage(stim_img)

            # send old/new triggers (1=studied, 0=not studied)
            if stim_img in curr_old_list:
                studied = 1
                stim_trigger = 4 
            elif stim_img in curr_new_list:
                studied = 0
                stim_trigger = 5 

            stim_trigger = stim_trigger + curr_block*30

            if using_labjack is True: 
                win.callOnFlip(send_trigger,stim_trigger)
                thisExp.addData('stim_trigger',stim_trigger)

            # add timestamp for img start
            thisExp.addData('img_start',globalClock.getTime())
            #thisExp.addData('curr_framerate',win.getActualFrameRate(infoMsg=''))
            # measure frame rate per trial will cause frame drop

            # initialize keyresp
            resp_real.keys = []
            resp_real.rt = []
            keylist = curr_old_keys + curr_new_keys
            pauseKeylist = ['backspace','return']
            keys = []
            continueKey=[]

            while routineTimer.getTime() < 5.000:
                checkForQuit()

                img.setAutoDraw(True)
                resp_stim.setAutoDraw(True)
                if curr_task == "strategic":
                    if curr_cond == "lib":
                        strat_stim    = lib_perc_stim
                        strat_stim000 = lib_perc_stim000
                        strat_stim_txt = lib_perc_text
                    elif curr_cond == "con":
                        strat_stim    = con_perc_stim
                        strat_stim000 = con_perc_stim000
                        strat_stim_txt = con_perc_text
                    strat_stim.setAutoDraw(True)
                win.flip()

                img000.setAutoDraw(True)
                resp_stim000.setAutoDraw(True)
                if curr_task == "strategic":
                    strat_stim000.setAutoDraw(True)
                    #thisExp.addData('strat_stim_txt',strat_stim_txt)
                win000.flip()

                for keys in event.getKeys():
                    isPaused = False
                    continueKey=[]

                    # if pressed one of the resp keys, break
                    if keys in keylist:
                        #print(keys)
                        event.clearEvents()
                        break 
                    # if pressed pause key, entre pause screen
                    elif keys in ['backspace']:
                        isPaused = True
                        thisPauseTimer = core.Clock()
                        event.clearEvents()

                        while thisPauseTimer.getTime() >= 0.000:
                            checkForQuit()
                            paused_rect.setAutoDraw(True)
                            paused.setAutoDraw(True)
                            win.flip()
                            paused_rect000.setAutoDraw(True)
                            paused000.setAutoDraw(True)
                            win000.flip()

                            # press enter to resume
                            for continueKey in event.getKeys():
                                if continueKey in ['return']:
                                    event.clearEvents() 
                                break 
                            if continueKey in ['return']:
                                event.clearEvents() 
                                break 
                            
                        paused_rect.setAutoDraw(False)
                        paused.setAutoDraw(False)
                        win.flip()
                        paused_rect000.setAutoDraw(False)
                        paused000.setAutoDraw(False)
                        win000.flip()

                        # add pause timestamp 
                        thisExp.addData('paused_this_trial',True)
                        thisExp.addData('pause_durr',thisPauseTimer.getTime())
                        # how long trial has been paused 
                        print(routineTimer.getTime())
                        print(thisPauseTimer.getTime())                    
                        #break 
                    
                    # if paused this trial & leaving pause screen,
                    # dial back routine clock & continue waiting for resp key
                    if isPaused is True:
                        routineTimer.addTime(-thisPauseTimer.getTime())
                        thisPauseTimer.reset()
                        event.clearEvents()
                        continue 

                # ==================== RESP =========================

                resp_real.keys = keys
                # if resp key pressed, break routine
                if keys in keylist:

                    resp_real.rt = routineTimer.getTime()    

                    # set resp_trigger values: "old" vs "new"
                    if resp_real.keys in curr_old_keys:
                        # answer OLD
                        if curr_old_keys == ['s', 'd', 'f']:
                            if resp_real.keys =='f':
                                resp_trigger = 11 # low
                            elif resp_real.keys =='d':
                                resp_trigger = 12 # med
                            elif resp_real.keys =='s':
                                resp_trigger = 13 # high
                        elif curr_old_keys == ['j', 'k', 'l']:
                            if resp_real.keys =='j':
                                resp_trigger = 11 # low
                            elif resp_real.keys =='k':
                                resp_trigger = 12 # med
                            elif resp_real.keys =='l':
                                resp_trigger = 13 # high
                    elif resp_real.keys in curr_new_keys:
                        # answer NEW
                        if curr_new_keys == ['j', 'k', 'l']:
                            if resp_real.keys =='j':
                                resp_trigger = 14 # low
                            elif resp_real.keys =='k':
                                resp_trigger = 15 # med
                            elif resp_real.keys =='l':
                                resp_trigger = 16 # high
                        elif curr_new_keys == ['s', 'd', 'f']:
                            if resp_real.keys =='f':
                                resp_trigger = 14 # low
                            elif resp_real.keys =='d':
                                resp_trigger = 15 # med
                            elif resp_real.keys =='s':
                                resp_trigger = 16 # high
                    elif resp_real.keys == [] or resp_real.keys == '' or resp_real.keys is None:
                        # no answer
                        resp_trigger = 10
                    else:
                        resp_trigger = 10

                    resp_trigger = resp_trigger + curr_block*30

                    if using_labjack is True:
                        win.callOnFlip(send_trigger,resp_trigger)

                    thisExp.addData('resp_trigger',resp_trigger)

                    # clear keyboard events
                    event.clearEvents()
                    break 

            #resp_real.keys = keys
            #resp_real.rt = routineTimer.getTime()    
            thisExp.addData('resp_real.key',resp_real.keys)
            thisExp.addData('resp_real.rt',resp_real.rt)
            if curr_task == "strategic":
                thisExp.addData('strat_stim_txt',strat_stim_txt)
            
            img.setAutoDraw(False)
            resp_stim.setAutoDraw(False)
            if curr_task == "strategic":
                strat_stim.setAutoDraw(False)
            win.flip()
            img000.setAutoDraw(False)
            resp_stim000.setAutoDraw(False)
            if curr_task == "strategic":
                strat_stim000.setAutoDraw(False)
            win000.flip()
            thisExp.addData('img_end',globalClock.getTime())

            # reset timer
            routineTimer.reset()

            # ==================== BLANK =========================
            # blank after resp & before feedback 

            thisExp.addData('blank_start_2',globalClock.getTime())

            # send trigger
            if using_labjack is True: 
                stim_trigger = 1 + curr_block*30
                #win.callOnFlip(send_trigger,stim_trigger)
                # not sending this one because feed start trig replaces it

            while routineTimer.getTime() < 0.200000:
                checkForPause(routineTimer)
                blank_stim.setAutoDraw(True)
                win.flip()
                blank_stim000.setAutoDraw(True)
                win000.flip()
        
            blank_stim.setAutoDraw(False)
            win.flip()
            blank_stim000.setAutoDraw(False)
            win000.flip()            
            thisExp.addData('blank_end_2',globalClock.getTime())

            # reset timer
            routineTimer.addTime(-0.200000)

            # ==================== FEED =========================

            feed_trigger = 0
            
            # timeout 
            #if resp_real.keys == None or resp_real.keys == [] or resp_real.keys in pauseKeylist:
            if resp_real.keys not in keylist:
                ans_text_real = "timeout"
                ans_text = time_out
                ans_text000 = time_out000
                is_correct = 999
                resp_type = "timeout"
                feed_durr = 2.000    # 2s "respond faster" reminder
                feed_trigger = 20  # timeout message
                
            elif studied == 1:
                if resp_real.keys in curr_old_keys:
                    ans_text_real = "correct"
                    ans_text = corr_ans
                    ans_text000 = corr_ans000
                    is_correct = 1 
                    resp_type = 'hit' 
                elif resp_real.keys in curr_new_keys:
                    ans_text_real = "incorrect"
                    is_correct = 0 
                    resp_type = 'miss'
                    if curr_task == "true_feed" or curr_task == "practice" or curr_cond == 'lib':
                        ans_text = incorr_ans 
                        ans_text000 = incorr_ans000
                    elif curr_task == "false_feed" and curr_cond == 'con':
                        roll_fpf = True 
                        fpf_chance = randint(0,100)
                        if fpf_chance < 75:
                            trial_is_fpf = True
                            print("con (miss) fpf trial")
                            ans_text = corr_ans
                            ans_text000 = corr_ans000
                        else:
                            trial_is_fpf = False
                            print("miss but not fpf")
                            ans_text = incorr_ans
                            ans_text000 = incorr_ans000

            elif studied == 0:
                if resp_real.keys in curr_new_keys:
                    ans_text_real = "correct"
                    ans_text = corr_ans
                    ans_text000 = corr_ans000
                    is_correct = 1 
                    resp_type = 'cr' 
                elif resp_real.keys in curr_old_keys:
                    ans_text_real = "incorrect"
                    is_correct = 0 
                    resp_type = 'fa' 
                    if curr_task == "true_feed" or curr_task == "practice" or curr_cond == 'con':
                        ans_text = incorr_ans
                        ans_text000 = incorr_ans000
                    elif curr_task == "false_feed" and curr_cond == 'lib':
                        roll_fpf = True 
                        fpf_chance = randint(0,100)
                        if fpf_chance < 75:
                            trial_is_fpf = True
                            print("lib (fa) fpf trial")
                            ans_text = corr_ans
                            ans_text000 = corr_ans000
                        else:
                            trial_is_fpf = False
                            print("FA but not fpf")
                            ans_text = incorr_ans
                            ans_text000 = incorr_ans000
            
            # set feed_trigger: hit/fa/miss/cr + true/false
            if resp_type == 'hit':
                feed_trigger = 21  # 
            elif resp_type == 'fa' and trial_is_fpf is not True:  
                # use `not True` instead of `is False` to avoid potential issues with None
                feed_trigger = 22  # FA true feed
            elif resp_type == 'fa' and trial_is_fpf is True:
                feed_trigger = 23  # FA FPF
            elif resp_type == 'cr':
                feed_trigger = 24
            elif resp_type == 'miss' and trial_is_fpf is not True:
                feed_trigger = 25  # miss true feed
            elif resp_type == 'miss' and trial_is_fpf is True:
                feed_trigger = 26  # miss FPF
            
            # do not show feedback if task is no_feed or strategic, 
            # BUT ONLY if there is a key resp
            if curr_task == "no_feed" or curr_task == "strategic":
                if resp_real.keys in curr_old_keys or resp_real.keys in curr_new_keys:
                    ans_text_real = None
                    ans_text = blank_ans
                    ans_text000 = blank_ans000
                    if curr_task == "no_feed":
                        feed_trigger = 27
                    elif curr_task == "strategic":
                        feed_trigger = 28
            
            if feed_trigger == 0:
                feed_trigger = 29 # catchall for everything else where feed trigger wasn't updated

            feed_trigger = feed_trigger + curr_block*30

            thisExp.addData('feed_start',globalClock.getTime())
            thisExp.addData("feed_trigger",  feed_trigger)

            # send trigger
            if using_labjack is True: 
                win.callOnFlip(send_trigger,feed_trigger)

            # redo feedback timing just to make sure
            if keys in keylist:
                feed_durr = 0.500
            else: 
                feed_durr = 2.000

            while routineTimer.getTime() < feed_durr: 
                checkForPause(routineTimer)
                ans_text.setAutoDraw(True)
                win.flip()
                ans_text000.setAutoDraw(True)
                win000.flip()
                # make sure no keys being logged by mistake during feed
                if len(defaultKeyboard.getKeys()):
                    defaultKeyboard.keys = None

            ans_text.setAutoDraw(False)
            win.flip()
            ans_text000.setAutoDraw(False)
            win000.flip()
            thisExp.addData('feed_end',globalClock.getTime())

            # record relevant info 
            thisExp.addData('curr_task', curr_task)
            thisExp.addData('n_cond', n_cond)
            thisExp.addData('curr_cond', curr_cond)
            thisExp.addData('phase', "test")
            thisExp.addData('stim_routine', "test_img")
            thisExp.addData('stim', stim_img)
            thisExp.addData("studied",    studied)
            thisExp.addData("is_correct", is_correct)
            thisExp.addData("resp_type",  resp_type)
            thisExp.addData("feed_text",  ans_text.text)
            thisExp.addData("is_correct_text",  ans_text_real)
            thisExp.addData("roll_fpf",   roll_fpf)
            thisExp.addData("fpf_chance", fpf_chance)
            thisExp.addData("trial_is_fpf", trial_is_fpf)
            thisExp.addData("curr_old_keys", curr_old_key_list)
            thisExp.addData("curr_new_keys", curr_new_key_list)

            # flush keys
            event.clearEvents()

            # reset timer
            routineTimer.addTime(-feed_durr)

            # ==================== BLANK =========================
            # blank after feed & before next trial (end of trial)
            
            thisExp.addData('blank_start_3',globalClock.getTime())

            # send trigger
            if using_labjack is True: 
                stim_trigger = 1 + curr_block*30
                win.callOnFlip(send_trigger,stim_trigger)

            while routineTimer.getTime() < 0.200000:
                checkForPause(routineTimer)
                blank_stim.setAutoDraw(True)
                win.flip()
                blank_stim000.setAutoDraw(True)
                win000.flip()
        
            blank_stim.setAutoDraw(False)
            win.flip()
            blank_stim000.setAutoDraw(False)
            win000.flip()            
            thisExp.addData('blank_end_3',globalClock.getTime())

            # reset timer
            routineTimer.addTime(-0.200000)
 
            # next trial
            thisExp.nextEntry()



    # ======================= DEFINE TASK PROCEDURES ======================

    def start_welcome():

        # ===========================================================
        # ========================= WELCOME =========================
        # ===========================================================
        
        show_instructions(curr_block=0,curr_msg=welcome_msg,curr_msg000=welcome_msg000)


    def run_practice():

        # ===========================================================
        # ========================= PRACTICE ========================
        # ===========================================================

        # study instructions 
        show_instructions(curr_block=0,curr_msg=study_0_ins,curr_msg000=study_0_ins000)

        # study trials
        run_study_trials(curr_block=0,curr_list=study_0_img,curr_task="practice")

        # test instructions
        show_instructions(curr_block=0,curr_msg=test_0_ins,curr_msg000=test_0_ins000)

        # test trials
        run_test_trials(curr_block=0,curr_list=test_0_img,curr_task="practice",n_cond=-1,
                        curr_old_list=old_list_0,curr_new_list=new_list_0)
    

    def run_true_feed():

        # ===========================================================
        # ======================= TRUE FEED =========================
        # ===========================================================

        print(f"CURRENT TASK: TRUE FEED")

        # study ins
        show_instructions(curr_block=1,curr_msg=study_1_ins,curr_msg000=study_1_ins000)

        # study trials
        run_study_trials(curr_block=1,curr_list=study_1_img,curr_task="true_feed")

        # test ins
        show_instructions(curr_block=1,curr_msg=test_1_ins,curr_msg000=test_1_ins000)

        # test block 1
        run_test_trials(curr_block=1,curr_list=test_1_img_1,curr_task="true_feed",n_cond=-1,
                        curr_old_list=old_list_1_1,curr_new_list=new_list_1_1)

        # midway msg
        print("test 1-1 done")
        show_instructions(curr_block=1,curr_msg=test_half_msg,curr_msg000=test_half_msg000)

        # test block 2
        run_test_trials(curr_block=1,curr_list=test_1_img_2,curr_task="true_feed",n_cond=-1,
                        curr_old_list=old_list_1_2,curr_new_list=new_list_1_2)


    def run_false_feed():

        # ===========================================================
        # ======================= FALSE_FEED ========================
        # ===========================================================
        print(f"CURRENT TASK: FALSE FEED")

        # study ins
        this_task = 'false_feed'
        task_pos = task_order.index(this_task)
        if task_pos == 0:
            print("TASK 2")
            show_instructions(curr_block=2,curr_msg=study_2_ins,curr_msg000=study_2_ins000)
        elif task_pos == 1:
            print("TASK 3")
            show_instructions(curr_block=2,curr_msg=study_3_ins,curr_msg000=study_3_ins000)

        # study trials
        run_study_trials(curr_block=2,curr_list=study_2_img,curr_task="false_feed")
        
        # test ins
        if task_pos == 0:
            show_instructions(curr_block=2,curr_msg=test_2_ins,curr_msg000=test_2_ins000)
        elif task_pos == 1:
            show_instructions(curr_block=2,curr_msg=test_3_ins,curr_msg000=test_3_ins000)
        
        # test block 1
        run_test_trials(curr_block=2,curr_list=test_2_img_1,curr_task="false_feed",n_cond=0,
                        curr_old_list=old_list_2_1,curr_new_list=new_list_2_1)

        # midway msg
        print("halfway done")
        show_instructions(curr_block=2,curr_msg=test_half_msg,curr_msg000=test_half_msg000)

        # test block 2
        run_test_trials(curr_block=2,curr_list=test_2_img_2,curr_task="false_feed",n_cond=1,
                        curr_old_list=old_list_2_2,curr_new_list=new_list_2_2)


    def run_strategic():

        # ===========================================================
        # ======================= STRATEGIC ===========================
        # ===========================================================
        print(f"CURRENT TASK: STRATEGIC")

        # study ins
        this_task = 'strategic'
        task_pos = task_order.index(this_task)
        if task_pos == 0:
            print("TASK 2")
            show_instructions(curr_block=3,curr_msg=study_2_ins,curr_msg000=study_2_ins000)
        elif task_pos == 1:
            print("TASK 3")
            show_instructions(curr_block=3,curr_msg=study_3_ins,curr_msg000=study_3_ins000)

        # study trials
        run_study_trials(curr_block=3,curr_list=study_strat_img,curr_task="strategic")

        # test ins
        if task_pos == 0:
            show_instructions(curr_block=3,curr_msg=test_2_ins,curr_msg000=test_2_ins000)
        elif task_pos == 1:
            show_instructions(curr_block=3,curr_msg=test_3_ins,curr_msg000=test_3_ins000)

        # get strat block lists 
        strat_test_img = {'con': test_strat_img_con, 'lib': test_strat_img_lib}
        strat_old      = {'con': old_list_strat_con, 'lib': old_list_strat_lib}
        strat_new      = {'con': new_list_strat_con, 'lib': new_list_strat_lib}
        
        # test list [base rate] for each block
        # cue shown follows strategic_cond_order[n_cond]
        if strat_cue_type == 'true':
            strat_cond1 = strategic_cond_order[0]
            strat_cond2 = strategic_cond_order[1]
        elif strat_cue_type == 'rev':
            strat_cond1 = flip_cond[strategic_cond_order[0]]
            strat_cond2 = flip_cond[strategic_cond_order[1]]

        # test block 1
        run_test_trials(curr_block=3,curr_list=test_strat_img[strat_cond1],curr_task="strategic",n_cond=0,
                        curr_old_list=strat_old[strat_cond1],curr_new_list=strat_new[strat_cond1])

        # midway msg
        print("halfway done")
        show_instructions(curr_block=3,curr_msg=test_half_msg,curr_msg000=test_half_msg000)

        # test block 2
        run_test_trials(curr_block=3,curr_list=test_strat_img[strat_cond2],curr_task="strategic",n_cond=1,
                        curr_old_list=strat_old[strat_cond2],curr_new_list=strat_new[strat_cond2])


    def run_no_feed():
        # ===========================================================
        # ======================= NO FEED ===========================
        # ===========================================================
        print(f"CURRENT TASK: NO FEED")

        # study ins
        show_instructions(curr_block=4,curr_msg=study_3_ins,curr_msg000=study_3_ins000)

        # study trials
        run_study_trials(curr_block=4,curr_list=study_3_img,curr_task="no_feed")

        # test ins
        show_instructions(curr_block=4,curr_msg=test_3_ins,curr_msg000=test_3_ins000)
        
        # test block 1
        run_test_trials(curr_block=4,curr_list=test_3_img_1,curr_task="no_feed",n_cond=-1,
                        curr_old_list=old_list_3_1,curr_new_list=new_list_3_1)

        # midway msg
        print("halfway done")
        show_instructions(curr_block=4,curr_msg=test_half_msg,curr_msg000=test_half_msg000)

        # test block 2
        run_test_trials(curr_block=4,curr_list=test_3_img_2,curr_task="no_feed",n_cond=-1,
                        curr_old_list=old_list_3_2,curr_new_list=new_list_3_2)


    def end_goodbye():

        # ===========================================================
        # ========================= GOODBYE =========================
        # ===========================================================

        show_instructions(curr_block=0,curr_msg=end_msg,curr_msg000=end_msg000)
        thisExp.saveAsWideText(filename + '.csv', delim='auto')
        print(f"FINISHED!")

        # mark experiment as finished
        endExperiment(thisExp, win=win)

    # ---------------------------------------------------------------

    # TO DO: 
    # add trig to mark start/end of blocks
    # TEST TRIAL: remove trig for BLANK before feedmsg if resp key is present (only send blank trig (1/31/61/91) if timeout)
    #    this means no sending resp keypress & blank start triggers at the same time
    # INS: same as above but for 9

    start_welcome()
    run_practice()
    run_true_feed()

    print(f"Task order: {task_order}")
    if task_order == ['strategic','false_feed']:
        run_strategic()
        run_false_feed()
    elif task_order == ['false_feed','strategic']:
        run_false_feed()
        run_strategic()

    #run_no_feed()

    end_goodbye()

    # ---------------------------------------------------------------


def saveData(thisExp):
    """
    Save data from this experiment
    
    Parameters
    ==========
    thisExp : psychopy.data.ExperimentHandler
        Handler object for this experiment, contains the data to save and information about 
        where to save it to.
    """
    filename = thisExp.dataFileName
    # these shouldn't be strictly necessary (should auto-save)
    thisExp.saveAsWideText(filename + '.csv', delim='auto')
    thisExp.saveAsPickle(filename)


def pauseExperiment(thisExp, win=None, timers=[], playbackComponents=[]):
    """
    Pause this experiment, preventing the flow from advancing to the next routine until resumed.
    
    Parameters
    ==========
    thisExp : psychopy.data.ExperimentHandler
        Handler object for this experiment, contains the data to save and information about 
        where to save it to.
    win : psychopy.visual.Window
        Window for this experiment.
    timers : list, tuple
        List of timers to reset once pausing is finished.
    playbackComponents : list, tuple
        List of any components with a `pause` method which need to be paused.
    """
    # if we are not paused, do nothing
    if thisExp.status != PAUSED:
        return
        
    # start a timer to figure out how long we're paused for
    pauseTimer = core.Clock()

    if thisExp.status == PAUSED and defaultKeyboard.getKeys(keyList=['backspace']):
        # pause any playback components
        for comp in playbackComponents:
            comp.pause()

    # check for quit while we wait to unpause
    while thisExp.status == PAUSED:
        # check for quit (typically the Esc key)
        if defaultKeyboard.getKeys(keyList=['escape']):
            endExperiment(thisExp, win=win)
        # sleep 1ms so other threads can execute
        clock.time.sleep(0.001)
    # if stop was requested while paused, quit
    if thisExp.status == FINISHED:
        endExperiment(thisExp, win=win)
    
    if thisExp.status == STARTED and defaultKeyboard.getKeys(keyList=['enter']):
        for comp in playbackComponents:
            comp.play()

    # reset any timers
    for timer in timers:
        timer.addTime(-pauseTimer.getTime())


def endExperiment(thisExp, win=None):
    """
    End this experiment, performing final shut down operations.
    
    This function does NOT close the window or end the Python process - use `quit` for this.
    
    Parameters
    ==========
    thisExp : psychopy.data.ExperimentHandler
        Handler object for this experiment, contains the data to save and information about 
        where to save it to.
    inputs : dict
        Dictionary of input devices by name.
    win : psychopy.visual.Window
        Window for this experiment.
    """
    if win is not None:
        # remove autodraw from all current components
        win.clearAutoDraw()
        win000.clearAutoDraw()
        # Flip one final time so any remaining win.callOnFlip() 
        # and win.timeOnFlip() tasks get executed
        win.flip()
        win000.flip()
    # mark experiment handler as finished
    thisExp.status = FINISHED
    logging.flush()


def quit(thisExp, win=None, thisSession=None):
    """
    Fully quit, closing the window and ending the Python process.
    
    Parameters
    ==========
    win : psychopy.visual.Window
        Window to close.
    inputs : dict
        Dictionary of input devices by name.
    thisSession : psychopy.session.Session or None
        Handle of the Session object this experiment is being run from, if any.
    """
    thisExp.abort()  # or data files will save again on exit
    # make sure everything is closed down
    if win is not None:
        # Flip one final time so any remaining win.callOnFlip() 
        # and win.timeOnFlip() tasks get executed before quitting
        win.flip()
        win000.flip()
        win.close()
        win000.close()

    logging.flush()

    if thisSession is not None:
        thisSession.stop()
    # terminate Python process
    core.quit()


# if running this experiment as a script...
if __name__ == '__main__':
    # call all functions in order
    expInfo = showExpInfoDlg(expInfo=expInfo)
    thisExp = setupData(expInfo=expInfo)
    logFile = setupLogging(filename=thisExp.dataFileName)
    win = setupWindow(expInfo=expInfo)
    #setupDevices(expInfo=expInfo, thisExp=thisExp, win=win)

    run(
        expInfo=expInfo, 
        thisExp=thisExp, 
        win=win,
        globalClock='float'
    )
    saveData(thisExp=thisExp)
    quit(thisExp=thisExp, win=win)
    
