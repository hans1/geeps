��    B      ,  Y   <      �  ?   �  0   �  3     ~   F     �     �  S   �  e   K     �     �  (  �     	  @   "	     c	     ~	     �	     �	     �	  P   �	     !
     2
     I
     U
     \
     k
  O   |
     �
  "   �
  '   �
  M   $     r  !   �     �  -   �     �        
   	       	   %     /  u   4     �     �     �     �     �            
   "     -     2     M     Y     l          �     �      �     �  *   �     
          %     4     :     G  R   h  5   �  7   �  �   )  ,   �  *   �  n   #  �   �      "      C  r  d  (   �  \         ]     v     �     �  '   �  u   �     Z     o     �  	   �     �     �  M   �     #  5   +  H   a  C   �     �  -   	     7  4   S      �  	   �     �     �     �  	   �  �        �     �     �     �     �  7   �     #  	   +     5     G     O     _     g     v     �     �      �  	   �  W   �     +     :     I     d     m     .       /      :           
          B   +       "   8   6   @          -   	   <          %   0                 3   $                  >   7   5   9      &   =      2                                                                         (       1              A   ,   '   )   ?      4   *      ;             #       !    	-bg #rrggbb     specify the background color of the tray icon
 	-hide           hide the main window initially
 	-v              print the version number and exit
 
# Background color of tray_icon (default is default GTK background color).  Note:  the commandline -bg option overrides this
 
# Enable the tray_icon
 
# Enable the tray_menu
 
# Set this to 1 to make the slider on the tray_icon vertical, or 0 for horizontal
 
# Set this to 1 to make the sliders vertical, or 0 for horizontal (only applies to the main window)
 
# Slider colorscheme
 
# Slider dimensions
 
# The numids of the sliders to display, in order.  It is okay to have comments
# after the numbers as long as the numbers are the first non-whitespace
# characters.  To get a list of the slider numids, run this command:
#    amixer controls
# NOTE:  This section must go at the end of the file!
 
# Tray slider dimensions
 
# Which slider to link with the tray_icon, identified by numid
 
# Which soundcard to use
 
# Window dimensions
 
# Window position
 
#EXAMPLE:
 # Config file for retrovol
 # This file should reside in the user's home directory and be named .retrovolrc
 /File/_Configure /File/_Exit completely /File/_Quit /_File Active Sliders Background Color Below you can chose which sliders to enable and in which order to display them. Border Color Cannot open file: %s
 for writing
 Cannot read file: %s
Using defaults...
 ERROR:  The -bg option requires a color to be supplied in the format #rrggbb
 Enable Tray Icon Enable Tray Icon Background Color Enable Tray Menu Error:  Failed to set background color to %s
 Error: could not create %s
 Hardware Horizontal Inactive Sliders Lit Color Main Reads ~/.retrovolrc for configuration options.  Additionally, the following
options may be given on the commandline:
 Retrovol - Configuration Segment Spacing Segment Thickness Slider Height Slider Margins Slider Orientation Slider Width Sound Card Tray Tray Icon Background Color Tray Slider Tray Slider Height Tray Slider Offset Tray Slider Orientation Tray Slider Width Unlit Color Usage: %s [-bg #rrggbb] [-hide]
 Vertical Volume mixer with bargraph style sliders.
 Volume: %d%% Volume: Muted _Config Window _Exit _Full Window Project-Id-Version: 
Report-Msgid-Bugs-To: pizzasgood@gmail.com
POT-Creation-Date: 2012-02-02 22:20-0500
PO-Revision-Date: 
Last-Translator: Argolance <argolance@free.fr>
Language-Team: 
Language: 
MIME-Version: 1.0
Content-Type: text/plain; charset=UTF-8
Content-Transfer-Encoding: 8bit
 	-bg #rrggbb     spécifie la couleur de fond de l'icône de la barre des tâches
 	-hide           Cache le panneau complet démarrage
 	-v              Donne le numéro de version et quitte
 
# Couleur de fond de l'icône de la barre des tâches (la couleur par défaut est celle de GTK).  Note: l'option -bg en ligne de commande prend le pas sur cela
 
# Activer l'icône de la barre des tâches
 
# Activer le menu contextuel de l'icône
 
#  1 pour positionner le potentiomètre de la barre verticalement , ou 0 pour le positionner horizontalement
 
# I pour disposer les potentiomètres verticalementl, 0 pour les disposer horizontalement (valeurs appliquées au panneau complet uniquement)
 
# Couleurs des potentiomètres
 
# Dimensions du potentiomètre
 
# Les potentiomètres sont affichés suivant leurs numéros d'identification.  Les commentaires après
# les nombres sont okay tant que les nombres sont en premiers et composés de caractères sans espace
# Pour obtenir la liste des numéros d'id, exécuter cette commande:
#    amixer controls
# NOTE:  Cette section doit impérativement se trouver en fin de fichier!
 
# Taille du potentiomètre de la barre
 
# Potentiomètre lié à l 'icône de la barre des tâches, identifié par le numéro d'id
 
#Carte-son à utiliser
 
# Dimensions de la fenêtre
 
# Position de la fenêtre
 
#EXEMPLE:
 # Fichier de configuration de retrovol
 # Ce fichier doit en principe se trouver dans le dossier administrateur de l'utilisateur et être nommé .retrovolrc
 /_Fichier/Configurer /Fichier/Quitter complètement /_Fichier/Quitter /_Fichier Potentiomètres activés Couleurs:
   Fond Choisissez ici quels potentiomètres activer et dans quel ordre les afficher. Bordure Impossible d'ouvrir le fichier: %s
 pour l'écriture
 "Impossible de lire le fichier: %s
Paramétres par défaut utilisés...
 ERREUR: l'option -bg requiert un format de couleur du type #rrggbb
 Potentiomètre disponible? Personnaliser la couleur de fond de l'icône: Menu contextuel disponible? Erreur: Impossible d'assigner la couleur de fond %s
 Erreur: Impossible de créer %s
 Matériel Horizontale Potentiomètres déactivés Pourcentage de volume actif Général Lit  ~/.retrovolrc pour les options de configuration. Les options suivantes
peuvent être éventuellement données en ligne de commandes:
 Retrovol - Configuration Espace entre les graduations Epaisseur des graduations Hauteur Marges Potentiomètres à glissière:
             Disposition Largeur Carte-son Barre des tâches Couleur Potentiomètre: Hauteur Positionnement Disposition Largeur Pourcentage de volume inactif Usage: %s [-bg #rrggbb] [-hide]
 Verticale Mixeur de volume avec potentiometres à glissière - indicateurs visuels de puissance.
 Volume à %d%% Volume à zero Fenêtre de _Configuration _Quitter _Panneau complet 