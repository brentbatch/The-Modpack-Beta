LJ @C:\Users\brent\AppData\Roaming\Axolot Games\Scrap Mechanic\User\User_76561198296305997\Mods\The modpack beta\Scripts\SE_Libs\globalscripts\stickyBombs.lua   	 G  self    +ûò%N4  7 >Dq888	8
887 6  TL'  2  4  7 6>D	7  T 4 7  >BNõ4 7 >4 7'   > T/2  4   >D TT4 7  >7 66) :  T7 664	 7
777 ' ( ( ' % >BNß7  7% 2 ;;>'   T+   ,  7  7% 2 ;+  ;;;	;
4	 7
7>;>7 )  9BN4  7 >D}4   >D
w7 T7  T4	 7
777 ' ( ( ' % >) :7  T_4	 7
7777 >  TS7)  774	 77'  '  '  >*  T 7> 7 777> 7 T! 7 > 77!'  :" 7#> 4 7$7%7&>4	 77'77( > 4	 77'7 > 7  7%) 2 ;;
;;;;;;7;	7*;
>B
N
BNG  	gravclient_setBombTargetworldPositionrotateZyx
atan2normalizezdirectiongetCharactercharacternormalLocaltransformPointgetShape	bodynew	vec3normalWorldpointWorldraycast	typedetonationTimegetGravityclient_createBombclient_killBombssendToClientsnetwork!PropaneTank - ExplosionSmallvelocitypositionexplodephysicssmmax	math	sortinsert
table	done	ammoserver_queued
pairsÉÂë£×ÇþÿµæÌ³Æÿ 			
"""###%%%%%%%%%%%%%%%%%%'''****++++,,,,,,.............//11122222222223345666677777778::;;;;<========>@@AAAABCCCCCCCDDDDDEEEEEEEEEFFFFFFFIIIIIIIIIIIIIIIIII++**NsomeFuckingNumber self  üdt  üt t tkey qqueued  qshapeId kposition  kvelocity  kdetonationTime  kcapacity  kexplodeOld  ki KbombIds J  k 	bomb  	cap 1illegalbombs .removebombs -" " "k id  bomb 7  shapeId }bombs  }z z zid wbomb  whit "Uresult  Utype Rtarget Qposition Mvelocity FpointLocal EnormalLocal  Edirection angle     '}w4   >3 4	 7		7		%
 >	:	::::	7	
	 7	
	 >	7	
	 7		 >	7	
	 7		>	7	 6		 	 T	7	 2
  9
	7	 6		9	G  	ammo
startsetVelocitysetPosition	gravdetonationTimevelocityposition  StickyBombcreateEffecteffectsmunpackself  (data  (shapeId $id  $position  $velocity  $detonationTime  $gravity  $bomb  H  4  % >G  stickyBomb.client_onCreate
printself   è   -¶4   >7 6  T7 2  97 66  T  7 2 ;;;;;
;>7 66:::7 7 >7 7 >:	:
:	G  normalLocalpointLocaltargetsetVelocitysetPositioneffectvelocityposition	typeclient_createBomb	ammounpack	
self  .data  .shapeId *id  *type  *position  *velocity  *target  *pointLocal  *normalLocal  *detonationTime  *gravity  *bombs (bomb   ì   [	4   >7 6  TG  4  >D7
 6

6
	
7


 7

>
7
 6

)  9	
BNóG  	stopeffect
pairs	ammounpack	self  data  shapeId illegalbombs  bombs   _ k   Ã  $ã¦=4  7 >DÜ4   >D
Ö7  T7 T)4 77>  T77:77	77
7 :7 777
4 774 77'  '  ' >7> >Tn* ::Tj7 Tg4 77>  T^77'  : 7> 4 777>4 777 >4 777>4 77  >4 77  >4 77 4 77'  '  'ÿÿ> = 4 774 77'  ' '  >4 77' '  '  > = 7 7 >4 777 >77	:77  T7!:7:T* ::7:T7 4 77'  '  7 >:77 :4 7 ' >	 T7 7!7>7 7"7>7'   T7 7!4 77'  '  ( > =7 7#>7 6)  9
B
N
(BN"G  	stopsetVelocitysetPositionrandom	gravdetonationTimeoldposlookRotation	quatrotateZyx
atan2	mathnormalizezdirectioncharacternormalLocalnewgetRotation	vec3setRotationeffectpointLocalworldRotationworldPositionpositionvelocitytargetexistssm	body	type	ammo
pairsçÌ³³æ¼ÿz								



















!!!!!!!!!!""""""""###%%%))))+++++++++++++,,,,,000000111113333355556666666666677778888=self  ädt  äß ß ßshapeId Übombs  ÜÙ Ù Ùid Öbomb  Ödirection :[angleDirection ProtatedNormal JangleNormal EnormalRotatedToY ?rot &     	åG  self   ô   Qé4  % >4 7 >D4  >D		7
 7>7 64 )  9B	N	õBNïG  k	stopeffect	ammo
pairsstickyBomb onDestroy
printself    shapeId bombs    id 	bomb  	 ø   Uø4  7  TG  4   T T T T % >4 74 72 ; ;;;;>G  server_queuedstickyBombinsert
tableqstickyBomb.server_spawnBomb: please fill in all parameters: shapeId, pos, velocity, detonationTime, capacityassertisHostsmshapeId  pos  velocity  detonationTime  capacity    	 'Rÿ4  7  TG  4   % >'  4 4 76   T2  >D BNý	 TG  4 74 7	3
 ;  T) T) ;>G         server_queuedinsert
table	ammostickyBomb
pairs>stickyBomb.server_clearBombs: requires argument 'shapeId'assertisHostsm shapeId  (detonate  (i   k v   Ý   !4  7  TG  4   % >4 76   T4 72  9 4 76 H 	ammostickyBomb<stickyBomb.server_getBombs: requires argument 'shapeId'assertisHostsmshapeId     /	 4   7  7  % > 7 2 2 2 3 (  9( 9( 92 2 3 ( 9( 9( 92 2 3 ( 9( 9( 9 7%	 %
 >4  7'  ' >' >4  7'	 '	 >' >4  7'	 '
 >' >4 	 7'
 '  >'	 >4  77>87 T6  T66  T666  T6666  TQ4  77%	 >Tù2  5 4 2	  :	4 2	  :	'  4	 1
 :
	4	 1
 :
	4	 1
 :
	4	 1
 :
	4	 1
  :
	4	 1
" :
!	4	 1
$ :
#	4	 1
& :
%	4	 1
( :
'	4	 1
* :
)	4	 1
, :
+	4	 1
. :
-	0  G   server_getBombs server_clearBombs server_spawnBomb onDestroy client_onRefresh client_onFixedUpdate client_killBombs client_setBombTarget client_onCreate client_createBomb server_onFixedUpdate server_onCreateserver_queued	ammostickyBomb<YOU ARE NOT ALLOWED TO COPY THIS SCRIPT, THY FOUL THIEF
errorlogBrent Batch	namegetAllPlayersplayersubtonumber-	gsub È³ ¸Ïô ´älocalId$MOD_DATA/description.json	open	jsonsmæÄÔè½²íèí¿¤×Ú¢	È àÆ[âÃ®äïý      
                                                                                                             #   % s % w  w        £  ¦ ã ¦ å ç å é ñ é ø ý ø ÿ ÿ description __localId allowedMods uuuid puuid1  Puuid2  Puuid3  Puuid4  PsomeFuckingNumber *&  