FasdUAS 1.101.10   ��   ��    k             l     �� ��    � � By Peter Walsh.. Please clean it up if you like. I took me towo seconds to put it together. I think the display dialog and if statement can be simplified, but I"m being lazy.       	  l     �� 
��   
 : 4 Shell scripts taken from kitzkikz of Mac OS X Hints    	     l     �� ��    E ? http://www.macosxhints.com/article.php?story=20050723123302403         l     �� ��    Q K Original shell script came from http://face.centosprime.com/macosxw/?p=201         l     ��  r         I    ��  
�� .sysodlogaskr        TEXT  m         Turn Dashboard on or off?     �� ��
�� 
btns  J           m        Turn On         m          Turn Off      !�� ! m     " "  Cancel   ��  ��    o      ���� 0 dashboard_trigger  ��     # $ # l    %�� % r     & ' & n     ( ) ( 1    ��
�� 
bhit ) o    ���� 0 dashboard_trigger   ' o      ���� 0 dashboard_choice  ��   $  * + * l   I ,�� , Z    I - . /�� - =    0 1 0 o    ���� 0 dashboard_choice   1 m     2 2  Turn On    . k    % 3 3  4 5 4 I   �� 6��
�� .sysoexecTEXT���     TEXT 6 m     7 7 A ;defaults write com.apple.dashboard mcx-disabled -boolean NO   ��   5  8�� 8 I    %�� 9��
�� .sysoexecTEXT���     TEXT 9 m     ! : :  killall Dock   ��  ��   /  ; < ; =  ( + = > = o   ( )���� 0 dashboard_choice   > m   ) * ? ?  Turn Off    <  @ A @ k   . 9 B B  C D C I  . 3�� E��
�� .sysoexecTEXT���     TEXT E m   . / F F B <defaults write com.apple.dashboard mcx-disabled -boolean YES   ��   D  G�� G I  4 9�� H��
�� .sysoexecTEXT���     TEXT H m   4 5 I I  killall Dock   ��  ��   A  J K J =  < A L M L o   < =���� 0 dashboard_choice   M m   = @ N N  Cancel    K  O�� O  S   D E��  ��  ��   +  P�� P l     ������  ��  ��       �� Q R S T����   Q ��������
�� .aevtoappnull  �   � ****�� 0 dashboard_trigger  �� 0 dashboard_choice  ��   R �� U���� V W��
�� .aevtoappnull  �   � **** U k     I X X   Y Y  # Z Z  *����  ��  ��   V   W  ��    "�������� 2 7�� : ? F I N
�� 
btns
�� .sysodlogaskr        TEXT�� 0 dashboard_trigger  
�� 
bhit�� 0 dashboard_choice  
�� .sysoexecTEXT���     TEXT�� J�����mvl E�O��,E�O��  �j O�j Y #��  �j O�j Y �a   Y h S �� T��
�� 
bhit T � [ [  T u r n   O n��  ��  ascr  ��ޭ