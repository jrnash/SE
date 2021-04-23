UNIT SE_COM;

INTERFACE

USES DOS, GRAPH;

CONST
{-----------------------------------------------------------------------------}
    VERSION     = 'Ver 1.0';                { Version number of Program       }
    REGSTAMP1   = 'Free Software';          { Registration Stamp 1            }
    REGSTAMP2   = 'Terms: GNU GPL';         { Registration Stamp 2            }
{   REGSTAMP3   = 'www.~.com';              { Registration Stamp 3            }
    StatHdrLen  = 150;   { X location where to place status, right of header  }
    StatStart   = 70;    { Y location to start placing statistics             }
    SPCSIDSTART = 120;   { Y location to start placing species ID's           }
    MINX        = 2;     { The MIN left   edge of the simulation screen (2)   }
    MINY        = 20;    { The MIN top    edge of the simulation screen (20)  }
    MAXX        = 502;   { The MAX right  edge of the simulation screen (502) }
    MAXY        = 440;   { The MAX bottom edge of the simulation screen (440) }
    VGAMAXX     = 639;   { The MAX right  edge of the VGA border  16 colors   }
    VGAMAXY     = 479;   { The MAX bottom edge of the VGA border              }
    CGRPHWID    = 134;   { The width of the Graph screen  (also # of points)  }
    CIOModes    = 19;    { Number of Modifiable Options                       }
    CMenuModes  = 7;     { Number of Options to display unique menu's for     }
    CCYCLE      = 800;   { Number of bug moves in a cycle (Generation)        }
    STARTBUGS   = 10;    { The number of bugs to begin the simulation with    }
    NUMOFTIMERS = 6;     { Used in TIMER_BLOCK_TYPE below                     }
    Y           = 2.0;   { Used for calculating probabilities of movments     }
    GENEMAX     = 100;   { Maximum value for a gene variable, avoids overflow }
    GENEMIN     = -100;  { Minimum value for a gene varialbe, avoids overflow }
    NUMOFGENES  = 5;     { array indexes genes 0 - 5                          }
    CGRPHOBJS   = 2;     { Number of graph objects                            }
    CGRPHBuff   = 3;     { Number of Graph Blocks to allocate                 }
    CMAXAGE     = 1000;  { The default age at which a bug dies, no children   }
    CMATURE     = 800;   { The default age for testing for reproduction       }
    CREPROSTR   = 1000;  { The default Minimum strength for reproduction      }
    CMAXSTR     = 1500;  { The default Maximum strength a bug can achieve     }
    MAXAGELIMP  = ($FFF0);{The + limit that the MaxAge gene can mutate        }
    MAXAGELIMN  = ($F);  { The - limit that the MaxAge gene can mutate        }
    MAXSTRLIMP  = ($FFF0);{The + limit that the MaxStr gene can mutate        }
    MAXSTRLIMN  = ($F);  { The - limit that the MaxStr gene can mutate        }
    MATURELIMP  = ($FFF0);{The + limit that the Mature gene can mutate        }
    MATURELIMN  = ($F);  { The - limit that the Mature gene can mutate        }
    REPROSTRLIMP= ($FFF0);{The + limit that the ReproStr gene can mutate      }
    REPROSTRLIMN= ($F);  { The - limit that the ReproStr gene can mutate      }

    CGARDWIDMin = 50;    { The - limit the garden width can become            }
    CGARDWIDMax = 85;    { The + limit the garden width can become            }
    CGARDHIGMin = 50;    { The - limit the garden height can become           }
    CGARDHIGMax = 85;    { The + limit the garden height can become           }

    EARLYGENERATIONS = 18;  { Trigger of when to keep bugs genes if population}
                            { drops < MINBUGS as apposed to give new genes    }

    BMenuRow1   = VGAMAXY - 25;
    BMenuRow2   = VGAMAXY - 15;
    BMenuRow3   = VGAMAXY - 5;
    BColwid     = Trunc(MAXX/5);
    BOffset     = Trunc(Bcolwid/2);

    Desc    : Array[1..CIOModes, 1..3] of STRING[20] =
              (
{Graph       } ('Population',       'Graph',               ''),
{Password    } ('Pass. of <CR>',    'turns OFF auto',      'password lock'),
{G Width     } ('Width of the',     'garden in',           'pixels'),
{G Height    } ('Height of the',    'garden in',           'pixels'),
{S Rate      } ('Rate bacteria is', 'replentished on',     'screen'),
{G Rate      } ('Rate bacteria is', 'replentished in',     'garden'),
{M Age       } ('Enables mutation', 'of maximum age',      ''),
{M Str       } ('Enables mutation', 'of maximum',          'strength'),
{M Mature    } ('Enables mutation', 'of age for',          'reproduction'),
{M ReproStr  } ('Enables mutation', 'of reproduction',     'strength'),
{Severity(B) } ('Number of genes',  'mutated on a',        'scale of 0-255'),
{Severity(G) } ('Mutation severity ','for each gene',      'scale of 0-255'),
{Save Sim    } ('Save simulation',  'to a file',           ''),
{Load Sim    } ('Load simulation',  'from a file',         ''),
{G Protection} ('Disables Garden',  'protection',          '(See README.TXT)'),
{Logging     } ('Turn logging to',  'a text file',         'on or off'),
{Log Period  } ('Logging interval', 'in seconds',          ''),
{M File Size } ('Max size log file ','can grow to',        '(x 100Kb)'),
{Exit Timer  } ('# of Minutes to',  'run before Exit',     '0 = Run Forever')
              );


    Menu     :  Array[1..CMenuModes, 1..5, 1..3] of STRING =
                ((
                   ('TAB',   'Options',  'Menu'),
{Graph Window}     ('Alt-L', 'Password', 'Lock'),
                   ('Alt-G', 'Disable',  'Garden'),
                   ('Alt-P', 'Pause',    'Program'),
                   ('Alt-X', 'eXit',     'Program')
                 ),(
{Password Options} ('TAB',   'Next',     'Option'),
                   ('ENTER', 'Change',   'Password'),
                   ('',      '',         ''),
                   ( #26,    'Next',     'Menu'),
                   ('ESC',   'Return',   'to Graph')
                 ),(
{Integer Options}  ('TAB',   'Next',     'Option'),
                   ( #24,    'Increase', 'Value'),
                   ( #25,    'Decrease', 'Value'),
                   ( #26,    'Next',     'Menu'),
                   ('ENTER', 'Enter',    'New Value')
                 ),(
{Boolean Options}  ('TAB',   'Next',     'Option'),
                   ( #24,    'Toggle',   'Value'),
                   ('',      '',         ''),
                   ( #26,    'Next',     'Menu'),
                   ('ESC',   'Return',   'to Graph')
                 ),(
{File Options}     ('TAB',   'Next',     'Option'),
                   ('ENTER', 'Specify',  'File'),
                   ('',      '',         ''),
                   ( #26,    'Next',     'Menu'),
                   ('ESC',   'Return',   'to Graph')
                 ),(
{Timer Options}    ('TAB',   'Next',     'Option'),
                   ('',      '',         ''),
                   ('',      '',         ''),
                   ( #26,    'Next',     'Menu'),
                   ('ENTER', 'Enter',    'New Value')
                 ),(
{Input Options}    ('',      '',         ''),
                   ('',      '',         ''),
                   ('',      '',         ''),
                   ('',      '',         ''),
                   ('ESC',   'Abort',    'Input')
                 ));


{#
Name_c : STRING[12] =
(#202#239#232#238#160#210#174#160#206#225#243#232);

ID_EMail_c : STRING[18] =
(#247#247#247#174#193#218#208#242#239#174#239#242#231#175#243#229#160#160);

NumofLines = 2;

SensitiveInfo : Array[1..NumofLines] of STRING[15] =

(#163#163#163#163#163#163#163#163#163#163#163#163#163#163#163,
#240#240#242#229#227#233#225#244#229#228#161#141#138#191#191);

#}

TYPE
{-----------------------------------------------------------------------------}
BYTEREC = RECORD
                low,high: BYTE;
End;
SHORTINTREC = RECORD
                low,high: SHORTINT;
End;
WORDREC = RECORD
                low,high: WORD;
End;
PTRREC = RECORD
                ofs,seg: WORD;
End;

BUG_PTR = ^BUG_CELL;

STATRCD = RECORD
     MAXAGE   : Word;  { The Avg age at which all bugs die without reproducing}
     MAXSTR   : Word;  { The Avg Max. strength all bugs can achieve           }
     MATURE   : Word;  { The Avg age after which all bugs may reproduce       }
     REPROSTR : Word;  { The Avg Min. strength all bugs must have for reproduc}
End;

BUG_CELL = Record
   Next  : BUG_PTR;
   Prev  : BUG_PTR;
   age   : Word;
   str   : Word;
   dir   : 0..5;
   posx  : Word;
   posy  : Word;
   colr  : Word;    { Color of bug on screen }
   mean  : Real;
   stddev: Real;

   MAXAGE   : Word;    { The age at which THIS bug dies without reproducing   }
   MAXSTR   : Word;    { The Maximum strength THIS bug can achieve            }
   MATURE   : Word;    { The age after which THIS bug may reproduce           }
   REPROSTR : Word;    { The minimum strength THIS bug must have for reproduc.}

   gene : ARRAY[0..NUMOFGENES] of SHORTINT;

   { 0 = Gene for forward           movement. }
   { 1 = Gene for right             movement. }
   { 2 = Gene for hard right        movement. }
   { 3 = Gene for reverse           movement. }
   { 4 = Gene for hard left         movement. }
   { 5 = Gene for left              movement. }

   prob : ARRAY[0..NUMOFGENES] of real;   { single = 4 Bytes }

   { 0 = Probability for forward    movement. }
   { 1 = Probability for right      movement. }
   { 2 = Probability for hard right movement. }
   { 3 = Probability for reverse    movement. }
   { 4 = Probability for hard left  movement. }
   { 5 = Probability for left       movement. }

End; { Bug_Cell }

LIST_TYPE = BUG_PTR; { Pointer to LL of all Bugs }

GRPH_BLOCK_PTR  = ^GRPH_BLOCK;
GRPH_BLOCK      = Record
                        Value : Array[1..CGRPHWID] of Word;
                        Next  : GRPH_BLOCK_PTR;
                        Prev  : GRPH_BLOCK_PTR;
                  End; { Record }
GRPH_CELL  = Record
                        Color  : Word;          { Color of Grph object        }
                        Max    : Word;          { Maximu Value of Graph Data  }
                        DataPtr: GRPH_BLOCK_PTR;{ Ptr to LL of Grph Blocks    }
			CurrPtr: GRPH_BLOCK_PTR;{ Ptr to current Block        }
                        Active : Boolean;       { Graph object active if TRUE }
                  End; { Record }
GRPH_MATRIX       = Array [1..CGRPHOBJS] of GRPH_CELL;


Species_RCD     = Record
                        stddev : Real;
                        Pop    : Integer;
                  End; { Record }

TIME_RCD        = Record
                        LstTriggered : Longint;
                        Interval     : Longint;
                  End;

TIMER_BLOCK_TYPE = Array[1..NUMOFTIMERS] of TIME_RCD;


RTP_PTR = ^RTPTYPE;
{ ----------------------------------------------------------------------------}
{ ---------------------------- Run Time Parameters ---------------------------}
{ ----------------------------------------------------------------------------}
RTPTYPE = RECORD          { Run Time Parameters                               }
    LL          : LIST_TYPE;{ Pointer to header node in bug list              }
    Curr_Bug    : BUG_PTR;  { Temp pointer to current bug                     }
    Avg         : STATRCD;  { Record of Averages used in Calc_Species for Log }
    BugMoves    : Word;     { Number of bug moves since last cycle            }
    tAutoLoad   : Boolean;  { Forces "autoload" of specified file if found    }
    Cycle_Cntr  : LongInt;  { Number of Cycles (Generations) so far           }
    Bact_on_Screen : Word;  { Counter of the # of bacteria outside Garden     }
    Bact_in_Garden : Word;  { Counter of the # of bacteria inside Garden      }
    NumofBugs   : Word;     { Counter of the number of live bugs on screen    }
    Dead_Bug    : Boolean;  { True if current Bug has died                    }
    GardenOn    : Boolean;  { Flag for Garden of Eden  Default = False        }
    tGProtect   : Boolean;  { Flag for protecting Garden from Veritcal Bugs   }
    Fwd_Travrs  : Boolean;  { Flag indicating LL traversel direction          }
    tLogging    : Boolean;  { Causes updates to log file per Logging Timer    }
    tSave       : Boolean;  { When FALSE causes SaveAll() to write to TEMP.$$$}
    Name        : STRING;   { Holds My Name after de-cryption                 }
    EMail       : STRING;   { Holds Internet Email address after de-cryption  }
    Password    : STRING;   { Holds password for Screen Saver                 }
    Key         : STRING;   { Holds Registration Key Needed to enable Password}
    tHaveKey    : Boolean;  { Indicates if Registration Key Entered           }
    SimFile     : String;   { Holds filename for Simulation File              }
    LogFile     : String;   { Holds filename for Log File                     }
    InputTimeout: Longint;  { Timeout value for Password entry                }
    IntroTime   : Longint;  { Time to display credit screen                   }
    MssgTimeout : Longint;  { Timer used to display user messages in second   }
    IOMode      : Byte;     { Value indicates mode of IO for IO Window        }
    IOMenu      : Byte;     { Value indicates mode of IO for menu             }
    bLogFSize100Kb : Byte;  { Max Size of Logging file in 100 Kilo Byte       }
    tStartS     : Longint;  { # of seconds into current day simulation started}
    wDays       : Word;     { Number of days simulation has been running      }
    tBS         : Boolean;  { Indicates if curr time is before sim start      }
                      { TRUE means next day but before sime started yesterday }
    LHr         : Word;     {                                                 }
    LMin        : Word;     { Hour, Min & Second last displayd as elapsed time}
    LSec        : Word;     {                                                 }
    LDays       : Word;     { & Days... (as above)                            }

    Timers      : TIMER_BLOCK_TYPE;  { Array of timers & Triggers             }

    ExpCycles   : Longint;  { Specifies Bug Cycles  before AutoExit (0=NoExit)}

    { Each elelment holds the avg of all stddev's for each bug species        }
    SpeciesID  : Array [0..NUMOFGENES] of Species_RCD;
    rStdDevLim : Real;    { Limit value a bug must exceed to be a viable      }
                          { member of a species.                              }

    wSMINX : Word;        { The left   edge of the simulation screen          }
    wSMINY : Word;        { The top    edge of the simulation screen          }
    wSMAXX : Word;        { The right  edge of the simulation screen          }
    wSMAXY : Word;        { The bottom edge of the simulation screen          }

    rSDENSITY : Real;     { Bacteria density on the Screen = 1.10 %           }
    rGDENSITY : Real;     { Bacteria density in the Garden = 6.25 %           }
    bGARDWID : Byte;      { The width of the Garden of Eden (thick bacteria)  }
    bGARDHIG : Byte;      { The hight of the Garden of Eden (thick bacteria)  }

    rSLIMPCT : Real;  { The max % of screen of bact to place/call          }
                      { when trying maintain ScreenBact, (0.006 =Aprox 12)    }
    rGLIMPCT : Real;  { The max % of garden of bact to place/call          }
                      { when trying maintain ScreenBact, (0.174 =Aprox 9)     }
    bSLIM    : Byte;  { The actual screen deposit limit                       }
    bGLIM    : Byte;  { The actual garden deposit limit                       }

    bSGRIDRESx  : Byte;  { Bacteria X Grid Resolution on Screen               }
    bSGRIDRESy  : Byte;  { Bacteria Y Grid Resolution on Screen               }
    bGGRIDRESx  : Byte;  { Bacteria X Grid Resolution in Garden               }
    bGGRIDRESy  : Byte;  { Bacteria Y Grid Resolution in Garden               }

    wGMAXTRYS   : Word;  { Maximum attempts to place bact/trigger             }
    wSMAXTRYS   : Word;  { Maximum attempts to place bact/trigger             }

    wSBACTMAX : Word;    { # of bacteria to try and maintain on screen        }
                         { (Last Num = % of total pixels)                     }
    wGBACTMAX : Word;    { The # of bact. to try and maintain in the garden   }
                         { num = % of total pixels                            }
    wSBACTWG : Word;     { The total # of bacteria to try and maintain on the }
                         { screen when the garden is enabled                  }

    wGARDNEARX : Word;
    wGARDNEARY : Word;
    wGARDFARX  : Word;
    wGARDFARY  : Word;

    wGRPHMINX  : Word;
    wGRPHMAXX  : Word;
    wGRPHMINY  : Word;
    wGRPHMAXY  : Word;
    wGRPHDens  : Word;  { Number of turns that a pixel on graph represents    }
    wGRPHCurs1 : Word;  { Marker for adding values to Block Curr1             }
    wGRPHCurs2 : Word;  { Marker for displaying values in Block Curr2         }
    wGRPHBlok1 : Word;  { index to Graph Block to store next value            }
    wGRPHBlok2 : Word;  { index to Graph Block to start displaying values     }
    GRPHMatrix : GRPH_MATRIX;      { Array of GRAPH CELLS                     }

    wBC_WEAK    : Word;  { Bug when weak                                }
    wBC_NORM    : Word;  { Bug when Normal                              }
    wBC_STR_Y   : Word;  { Bug when Strong and Young                    }
    wBC_STR_O   : Word;  { Bug when Strong and almost Mature            }
    wBC_Vry_O   : Word;  { Bug when Old but almost of Mature Strength   }
    wBACT_COL   : Word;  { Bacteria Color                                     }
    wSBK_COL    : Word;  { Background Color Bug Screen                        }
    wGBK_COL    : Word;  { Background Color of graph                          }
    wBORDER_COL : Word;  { Color of border around simulation area             }
    wHILIT_COL  : Word;  { Color of highlighted text                          }
    wTEXTF_COL  : Word;  { Forground color for text                           }
    wTEXTB_COL  : Word;  { Bacground color for text                           }

    wMAXBUGS : Word;     { The maximum number of bugs allowed                 }
    bMINBUGS : Byte;     { The minimum number the bug population can drop to  }
                         { Must be <= Bact_State_Lo% of MaxBugs!              }
    bBACTERIA : Byte;    { Units of energy supplied by eating 1 bacteria      }

    tMAXAGE   : Boolean; { TRUE activates possible mutation of gene MAXAGE    }
    tMAXSTR   : Boolean; { TRUE activates possible mutation of gene MAXSTR    }
    tMATURE   : Boolean; { TRUE activates possible mutation of gene MATURE    }
    tREPROSTR : Boolean; { TRUE activates possible mutation of gene REPROSTR  }
    bMUTRATNG : Byte;    { Number of genes mutated during reproduction on a   }
                         { scale of 1 - 255 resulting in a number 0 - 5       }
    bMUTRATMS : Byte;    { Mutation Severity for each gene mutated on a scale }
                         { of 1 - 255 resulting in a change of 0 - 5          }

    wErrorNum1  : Word;  { Var to store runtime error code 1                  }
    wErrorNum2  : Word;  { Var to store runtime error code 2                  }
End; { RTP Record }

IMPLEMENTATION
{ ----------------------------------------------------------------------------}
END.
