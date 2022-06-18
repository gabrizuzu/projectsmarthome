-- Data Analytics 1: Association rule learning

-- contesto: Dispositivi della Smarthome					

-- la seguente procedure serve per analizzare le abitudini di un determinato utente della smarthome dato in input, 
-- nel contesto dei dispositivi e delle loro impostazioni. 
-- L'obiettivo della seguente analytics è individuare 
-- le association rule tra le varie impostazioni dispositivo fatte dall' utente.
-- In particolare prenderemo in studio tutte le impostazioni dispositivo fatte dall'utente
-- poi per ognuna di esse cercheremo le altre impostazioni dispositivo fatte dallo stesso utente su dispositivi diversi in un intervallo di tempo di 60 minuti
-- E determineremo una association rule che rispetti i livelli di confidence e support predeterminati 
-- -----------------------------------------------------------------------------------------------------------

drop procedure if exists AbitudiniUtente;
delimiter $$
create procedure AbitudiniUtente(in _utente varchar(50))
begin 

if _utente not in(
	select NomeUtente
    from Account
	)
then signal sqlstate '45000' set message_text= 'Account errato';
end if;
    
set @confidence = 2;
-- individuo gli items e le transazioni
-- ImpostazioniTarget è la cte contente tutte le impostazioni dispositivo fatte dall'utente di nostro interesse
	with ImpostazioniTarget as(
		select *
        from ImpostazioniDispositivo ID
        where ID.Nickname = _utente
    ),
-- applicando il seguente selfjoin determino quante volte l'utente ha fatto impostazioni dispositivo 
-- di due stessi dispositivi diversi in un range temporale di 60 minuti
	Abitudini as(
    select IT.Nickname, IT.Dispositivo as D1, IT1.Dispositivo as D2, count(*) as Quanti 
    from ImpostazioniTarget IT
    inner join ImpostazioniTarget IT1
    on (IT.Nickname = IT1.Nickname
		and IT.Dispositivo > IT1.Dispositivo -- ovviamente raggruppando per D1 e D2, le coppie risulterebbero ripetute due volte (ad esempio prima 8 e 9 e poi 9 e 8, che sono la stessa coppia) per questo impongo D1>D2 in modo di prendere solo una volta la coppia 
        and (IT.Inizio between IT1.Inizio - interval 30 minute and IT1.Inizio + interval 30 minute))
	group by IT.Nickname,IT.Dispositivo, IT1.Dispositivo
    )
-- tra le coppie di impostazioni trovate prima cerco di determinare le regole forti imponendo il numero di volte maggiore ad 
-- un determinato valore di confidence prestabilito

	select *
    from Abitudini A
    where A.Quanti > @confidence;
    
    
end $$
delimiter ;

-- Data Analytics 2: Ottimizzazione dei Consumi Energetici

-- contesto: Dispositivi della Smarthome					

-- la seguente procedure serve per creare un piano di ottimizzazione riguardante l’efficienza energetica 
-- affinchè si sfrutti al meglio l’impiego di energia rinnovabile disponibile. 
-- -----------------------------------------------------------------------------------------------------------




drop procedure if exists analytics_2;
DELIMITER $$
create procedure analytics_2()
begin
	declare consumo_dispositivi double default 0;
	declare consumo_condizionamento double default 0;
	declare consumo_illuminazione double default 0;
	declare consumo_totale double default 0;
    declare tempo timestamp default '2022-03-21 18:29:40';
	declare potenza_pannello double default 0;
	declare ultimo_irraggiamento integer default 0;
	declare irraggiamento_previsto double default 0;
    declare nome_dispositivo varchar(50)  default 0;
	declare dispositivo_da_attivare integer default 0;
	declare consumo_programma double default 0;
    declare durata_programma integer default 0;
	declare inizio_programma timestamp;
	declare fine_programma timestamp;
	declare energia_disponibile double default 0;
	declare energia_mancante double default 0;
	declare energia_batteria double default 0;

	#consumo totale dovuto ai Dispositivi 
	select sum(ConsumoDispositivo) into consumo_dispositivi
	from ImpostazioniDispositivo ID
    natural join GestoreCentrale GC 
	where tempo between Inizio and ifnull(TimestampFine,now());

    
    #consumo totale dovuto ai Condizionatori 
    select sum(ConsumoClima) into consumo_condizionamento
	from ImpostazioneClima
		natural join GestoreCentrale 
	where tempo between Inizio and ifnull(TimestampFine,now());
    
    #consumo totale dovuto alle Luci 
	select sum(RL.ConsumoLuce) into consumo_illuminazione
    from RegolazioneLuce RL
			natural join GestoreCentrale
    where tempo between Inizio and ifnull(TimestampFine,now());
     
	set consumo_totale = ifnull(consumo_dispositivi,0) + ifnull(consumo_condizionamento,0) + ifnull(consumo_illuminazione,0);
                         select consumo_totale;
	select Produzione, (Produzione/15) into ultimo_irraggiamento, potenza_pannello
    from Sorgente
    where Timestamp = ( select max(Timestamp)
						from Sorgente
					    where Timestamp <= tempo);
   
		select sum(Produzione)/15 into irraggiamento_previsto
		from Sorgente S
		where S.Timestamp >= tempo - interval 1 month 
			and hour(S.Timestamp) between hour(tempo) and hour(tempo) + 2;
            

        
		if irraggiamento_previsto >= ultimo_irraggiamento then
		# ho la possibilità di anticipare l'accensione di un dispositivo quindi invio un suggerimento sull'app,
		# in quanto il livello di irraggiamento mi permette di fronteggiare il nuovo consumo
		
	   set energia_disponibile = irraggiamento_previsto;
																															  
		# trovo il programma che si 'avvicina' di piu' al valore di energia disponibile
		select ID.ConsumoDispositivo,ID.Inizio,ID.Dispositivo into consumo_programma, inizio_programma, dispositivo_da_attivare
		from ImpostazioniDispositivo ID
		order by abs(ID.ConsumoDispositivo - energia_disponibile)
		limit 1;
        
        select Nome into nome_dispositivo
        from Dispositivo
        Where CodiceDispositivo = dispositivo_da_attivare;
        
        select TimestampFine into fine_programma
        from GestoreCentrale
        where TimestampInizio = inizio_programma;
        
		 set durata_programma = TIMESTAMPDIFF(SECOND,fine_programma,inizio_programma);
       
		if  energia_disponibile >= consumo_programma then -- invio il suggerimento sull'app tranquillamente, qualora l'energia prodotta fosse maggiore del consumo il resto verrà venduta
        insert into Suggerimento (Testo,Dispositivo,DataRegistro,Fascia)
		values ('Si consiglia di usare il dispositivo in questione nella data indicata.',dispositivo_da_attivare,tempo,2); 
		select * from porta;
        end if;

		if consumo_programma > energia_disponibile then -- controllo in batteria se ho energia sufficiente per l'accensione del dispositivo con quel programma
			select * from Dispositivo;
            set energia_mancante = (consumo_programma - energia_disponibile) * durata_programma*60 / 3600;
			set energia_batteria =  (select EnergiaImmagazzinata from Batteria);
			
			if energia_batteria > energia_mancante then -- se in batteria ho il rimanente per fronteggiare il consumo del programma da attivare, 
			-- posso inviare il suggerimento tranquillamente
			insert into Suggerimento (Testo,Dispositivo,DataRegistro,Fascia)
					values ('Si consiglia di usare il dispositivo in questione nella data indicata.',dispositivo_da_attivare,tempo,2); 
			end if;
				end if;
					end if;
 
end $$
DELIMITER ;
