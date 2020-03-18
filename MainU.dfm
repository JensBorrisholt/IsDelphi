object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'IsDelphi'
  ClientHeight = 427
  ClientWidth = 1056
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Menu = MainMenu1
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object lvFiles: TListView
    Left = 0
    Top = 0
    Width = 1056
    Height = 408
    Align = alClient
    BorderStyle = bsNone
    Columns = <
      item
        Caption = 'Name'
        Width = 150
      end
      item
        Caption = 'Path'
        Width = 300
      end
      item
        Caption = 'Date Modified'
        Width = 110
      end
      item
        Caption = 'Type'
        Width = 120
      end
      item
        Alignment = taRightJustify
        Caption = 'Size'
        Width = 80
      end
      item
        Caption = 'Processor'
        Width = 60
      end
      item
        Caption = 'Compiler'
        Width = 135
      end
      item
        Caption = 'SKU'
        Width = 80
      end>
    DoubleBuffered = True
    GridLines = True
    ReadOnly = True
    RowSelect = True
    ParentDoubleBuffered = False
    ParentShowHint = False
    PopupMenu = PopupMenu1
    ShowHint = False
    SortType = stData
    TabOrder = 0
    ViewStyle = vsReport
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 408
    Width = 1056
    Height = 19
    Panels = <
      item
        Width = 150
      end
      item
        Width = 50
      end>
  end
  object ActionList1: TActionList
    OnUpdate = ActionList1Update
    Left = 112
    Top = 224
    object actOpenFile: TAction
      Category = 'File'
      Caption = 'Open File(s)...'
      ImageIndex = 0
      ShortCut = 16463
      OnExecute = actOpenFileExecute
    end
    object actOpenFolder: TAction
      Category = 'File'
      Caption = 'Open Folder(s)...'
      ImageIndex = 1
      ShortCut = 16454
      OnExecute = actOpenFolderExecute
    end
    object actExit: TAction
      Category = 'File'
      Caption = 'Exit'
      ImageIndex = 2
      ShortCut = 32856
      OnExecute = actExitExecute
    end
    object actShowInExplorer: TAction
      Caption = 'Show in Explorer'
      ShortCut = 16453
      OnExecute = actShowInExplorerExecute
    end
    object actCopyToClipboard: TAction
      Category = 'Edit'
      Caption = 'Copy to Clipboard'
      ShortCut = 16451
      OnExecute = actCopyToClipboardExecute
    end
    object actRefresh: TAction
      Category = 'View'
      Caption = 'Refresh'
      ShortCut = 116
      OnExecute = actRefreshExecute
    end
    object actCancel: TAction
      Category = 'View'
      Caption = 'Cancel'
      ShortCut = 16497
      OnExecute = actCancelExecute
    end
  end
  object PopupMenu1: TPopupMenu
    Left = 208
    Top = 248
    object CopytoClipboard2: TMenuItem
      Action = actCopyToClipboard
    end
    object N2: TMenuItem
      Caption = '-'
    end
    object OpeninExplorer1: TMenuItem
      Action = actShowInExplorer
    end
  end
  object MainMenu1: TMainMenu
    Left = 40
    Top = 232
    object File1: TMenuItem
      Caption = 'File'
      object OpenFiles1: TMenuItem
        Action = actOpenFile
      end
      object OpenFolders1: TMenuItem
        Action = actOpenFolder
      end
      object N1: TMenuItem
        Caption = '-'
      end
      object Exit1: TMenuItem
        Action = actExit
      end
    end
    object Edit1: TMenuItem
      Caption = 'Edit'
      object CopytoClipboard1: TMenuItem
        Action = actCopyToClipboard
      end
    end
    object View1: TMenuItem
      Caption = 'View'
      object Cancel1: TMenuItem
        Action = actCancel
      end
      object Refresh1: TMenuItem
        Action = actRefresh
      end
    end
  end
end
