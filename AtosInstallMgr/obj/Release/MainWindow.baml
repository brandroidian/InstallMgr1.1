   M S B A M L   `   `   `  ���� I  EAtosInstallMgr, Version=1.0.0.0, Culture=neutral, PublicKeyToken=null/clr-namespace:AtosInstallMgrAtosInstallMgr      AtosInstallMgr.MainWindow   \ XPresentationFramework, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35R NWindowsBase, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35W SPresentationCore, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35D 9http://schemas.microsoft.com/winfx/2006/xaml/presentation    R NSystem.Xaml, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089:x,http://schemas.microsoft.com/winfx/2006/xaml     @d2http://schemas.microsoft.com/expression/blend/2008     Jmc;http://schemas.openxmlformats.org/markup-compatibility/2006     .localclr-namespace:AtosInstallMgr     -     �Name$  MainWindow1��$	��603��$	��878�� � Topmost .  � WindowStartupLocation$ CenterScreen=�����  �� EndPoint$ 0.5,1&� �� 
StartPoint$ 0.5,0&�.���  � Color$ 	#FFACB7DA�� � Offset$ 0.911Q�� $ 	#FF0C35BD��.��� $��	0,0,2,-21q�.+�&   System.Windows.Controls.DataGrid  -     Name$ dataGrid��$	��309��$��10,200,16,0q�$	��Top=����	#FFCFCFCF   AutoGenerateColumns .  	   
IsReadOnly	 . 
 �� IsTextSearchEnabled
 .    CanUserAddRows .     Columns 0  *System.Windows.Controls.DataGridTextColumn  ,  &System.Windows.Controls.DataGridColumn   Width5  /System.Windows.Controls.DataGridLengthConverter$
 Auto    
IsReadOnly . 1  +System.Windows.Controls.DataGridBoundColumn   Binding ��  �� Path$
 name�  $
 Auto  .  �� $ RAP_Manufacturer�  $
 Auto  .  �� $ RAP_ProductVersion�  $
 Auto  .  �� $ RAP_ProductName�  $
 Auto  .  �� $ RAP_ProductCode�  $
 Auto  .  �� $ CTMS_ID�  $
 Auto  .  �� $ CTMS_ApplicationName�  $
 Auto  .  �� $ Install�  $
 Auto  .  �� $ 	Uninstall�  $
 Auto  .  �� $ Documentation�  $
 Auto  .  �� $ Description�  $
 Auto  .  �� $ Comments��� -    ��Name$ button_Install��$��Install Application��$
��Left=�$��285,528,0,0q�$	��Top=�$	��104��$��29�� J� Effect 3  -System.Windows.Media.Effects.DropShadowEffect  �� -   $ button_Uninstall��$��Uninstall Application��$
��Left=�$��404,528,0,0q�$	��Top=�$	��121��$��29��   �� -   $ button_Documentation��$��App Documentation��$
��Left=�$��541,528,0,0q�$	��Top=�$	��118��$��29��   �� -    ��Name$ textBox_SearchText��$
��Left=�$��33��$��285,150,0,0q�$	��Top=�$	��374�����	#FFF0F0F0$��Center=� �� 
CaretBrush �	#00000000 � ToolTip$ Enter Search Term Here��$��20(��� -   $ textBox_Text��$
��Left=�$��33��$��145,150,0,0q� �� TextWrapping$
 Wrap=�$	��Top=�$	��120��$��Center=�$��Right=�
������ 
����������	#00000000$��20(� J� 	AllowDrop .  |�.   J� IsHitTestVisible .  ��.  �� -    ��Name$ 
Image_Logo��$
��Left=�$	��100��$��
464,26,0,0q�$	��Top=�$	��388��