   M S B A M L   `   `   `  ����I  EAtosInstallMgr, Version=1.0.0.0, Culture=neutral, PublicKeyToken=null/clr-namespace:AtosInstallMgrAtosInstallMgr  5   	       AtosInstallMgr.MainWindow   5   	   \ XPresentationFramework, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35R NWindowsBase, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35W SPresentationCore, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35D 9http://schemas.microsoft.com/winfx/2006/xaml/presentation    5   	   R NSystem.Xaml, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089:x,http://schemas.microsoft.com/winfx/2006/xaml     5   	   @d2http://schemas.microsoft.com/expression/blend/2008     5   	   Jmc;http://schemas.openxmlformats.org/markup-compatibility/2006     5   	   .localclr-namespace:AtosInstallMgr     5   	   -   5          �Name$  MainWindow1��5   	   $	��603��5      $	��878��6'    � Topmost .  � WindowStartupLocation$ CenterScreen=�6B   ��5      �� 5	   
    �� EndPoint$ 0.5,1&�6    �� 
StartPoint$ 0.5,0&�6/   .��5
      �  � Color$ 	#FFACB7DA��6    � Offset$ 0.911Q�6-   � 5      $ 	#FF0C35BD��6   5      .��5      � $��	0,0,2,-21q�6   .+�5   
   &   System.Windows.Controls.DataGrid  -   5          Name$ dataGrid��5      $	��309��6%   $��10,200,16,0q�62   $	��Top=�6G   ���	#FFCFCFCF   AutoGenerateColumns .  	   
IsReadOnly	 . 
 �� IsTextSearchEnabled
 .    CanUserAddRows .     Columns 5      0  *System.Windows.Controls.DataGridTextColumn  5      ,  &System.Windows.Controls.DataGridColumn   Width5  /System.Windows.Controls.DataGridLengthConverter$
 Auto 6%      
IsReadOnly . 1  +System.Windows.Controls.DataGridBoundColumn   Binding 62   ��  �� Path$
 name�6P     5      $
 Auto 6%    .  62   �� $ RAP_Manufacturer�6\     5      $
 Auto 6%    .  62   �� $ RAP_ProductVersion�6^     5      $
 Auto 6%    .  62   �� $ RAP_ProductName�6[     5      $
 Auto 6%    .  62   �� $ RAP_ProductCode�6[     5      $
 Auto 6%    .  62   �� $ CTMS_ID�6S     5      $
 Auto 6%    .  62   �� $ CTMS_ApplicationName�6`     5      $
 Auto 6%    .  62   �� $ Install�6S     5      $
 Auto 6%    .  62   �� $ 	Uninstall�6U     5      $
 Auto 6%    .  62   �� $ Documentation�6Y     5      $
 Auto 6%    .  62   �� $ Description�6W     5      $
 Auto 6%    .  62   �� $ Comments�6T   5      �� 5   
   -   5         ��Name$ button_Install��5      $��Install Application��6)   $
��Left=�6G   $��285,528,0,0q�6b   $	��Top=�6w   $	��104��6�   $��29��6�    J� Effect 5       3  -System.Windows.Media.Effects.DropShadowEffect  5!      5#      �� 5$   
   -   5        $ button_Uninstall��5$      $��Uninstall Application��6+   $
��Left=�6K   $��404,528,0,0q�6f   $	��Top=�6{   $	��121��6�   $��29��6�    5%        5&      5(      �� 5)   
   -   5        $ button_Documentation��5)      $��App Documentation��6/   $
��Left=�6K   $��541,528,0,0q�6f   $	��Top=�6{   $	��118��6�   $��29��6�    5*        5+      5-      �� 5.   
   -   5         ��Name$ textBox_SearchText��5.      $
��Left=�6.   $��33��6I   $��285,150,0,0q�6U   $	��Top=�6j   $	��374��6�   ���	#FFF0F0F0$��Center=�6�    �� 
CaretBrush �	#00000000 � ToolTip$ Enter Search Term Here��6�   $��20(�6�   �� 5/   
   -   5        $ textBox_Text��5/      $
��Left=�6(   $��33��6C   $��145,150,0,0q�6O    �� TextWrapping$
 Wrap=�6d   $	��Top=�6x   $	��120��6�   $��Center=�6�   $��Right=�6�   
������ 
����������	#00000000$��20(�6%   J� 	AllowDrop .  |�.   J� IsHitTestVisible .  ��.  6p  �� 50   
   -   5         ��Name$ 
Image_Logo��50      $
��Left=�6$   $	��100��6?   $��
464,26,0,0q�6L   $	��Top=�6`   $	��388��6x   51      52      