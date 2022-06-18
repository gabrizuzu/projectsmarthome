/*
1° funzionalità di back-end: GENERA SUGGERIMENTO RELATIVO AD UN DISPOSITIVO
Procedure che genera suggerimenti di utilizzo dei dispositivi dipendentemente dalla disponibilità di energia rinnovabile. 
*/

drop procedure if exists CreazioneSuggerimento; 
delimiter $$
create procedure CreazioneSuggerimento (in _inizio timestamp, out Sugg varchar(255)) 
begin
 declare Tot double default 0;
 declare NumeroProduzioni int default 0;
 declare StimaEnergia double default 0;
 declare Partenza timestamp default null;
 declare Suggested  varchar(50) default '';
 declare durata integer default 0;
 
  select SUM(Produzione), Count(*) into Tot, NumeroProduzioni 
  from Sorgente
  where month(timestamp)=month(current_timestamp) and year(timestamp)=year(current_timestamp)
  and hour(_inizio) between hour(_inizio) and  hour(_inizio)+1;
  
set StimaEnergia=Tot/NumeroProduzioni;  -- faccio una stima dell'energia che andrò a produrre

select NomeDispositivo into Suggested
from Dispositivo
where CodiceDispositivo=(select Dispositivo 
						from ImpostazioniDispositivo
						where ConsumoDispositivo =(  select MAX(ConsumoDispositivo)
													from ImpostazioniDispositivo
													where ConsumoDispositivo<=StimaEnergia));-- scelgo un dispositivo la cui impostazione abbia un costo energetico che può essere coperto dalla produzione stimata
                                                   
set durata =TIMESTAMPDIFF(SECOND, Partenza, (SELECT TimestampFine FROM GestoreCentrale WHERE TimestampInizio=Partenza AND NomeUtente=_nomeutente));

set Sugg = concat('Suggerimento : Si consiglia di usare il dispositivo ', Suggested, ' dalle ore ', hour(current_timestamp), ' di Domani per', Durata ,'secondi.'); 
end $$

/*
2° funzionalità di back-end: STIMA DEL CONSUMO DELLA CLIMATIZZAZIONE

Stored procedure che prende in ingresso un’impostazione di climatizzazione, prendendone il timestampInizio, timestampFine, codice Dispositivo e l'utente che la esegue, 
e restituisce in uscita la stima del consumo e l'energia prodotta in quel lasso di tempo (facendo un approssimazione considerando il giorno di inizio dell'impostazione e il giorno di fine)
*/
-- la seguente funzione mi servirà poi per calcolare la stima del consumo relativa alla mia impostazioneclima
drop function if exists CalcoloConsumoClima;
delimiter $$
create function CalcoloConsumoClima ( climatizzatore_ int, utente_ varchar(50),inizio_ timestamp,fine_ timestamp)
returns double deterministic
begin
	declare consumo double default 0;
    declare temperaturaRichiesta int default 0;
    declare temperaturaAttuale int default 0;
    declare energia double default 0;
    
    
    select IC.Temperatura, EE.TemperaturaIN,EE.energiaNecessaria into temperaturaRichiesta, temperaturaAttuale,energia
    from ImpostazioneClima IC
    inner join Climatizzatore C
    on IC.Climatizzatore = C.CodClimatizzatore
    inner join EfficienzaEnergetica EE
    on (C.Ubicazione = EE.Ubicazione
    and IC.Inizio between EE.Tempo and EE.Tempo + interval 30 minute)
    where IC.Inizio=inizio_
    and IC.Nickname= utente_
    and IC.Climatizzatore= climatizzatore_;
    
    
    set consumo=((abs(temperaturaRichiesta - temperaturaAttuale)*energia)*(timestampdiff(hour,fine_,inizio_)))/1000;
    return consumo;
end $$
delimiter ;

drop procedure if exists consumo_climatizzazione;
delimiter $$

create procedure consumo_climatizzazione(
											in _inizio timestamp,
                                            in _fine timestamp,
                                            in _cod_climatizzatore int,
                                            in _nome_utente varchar(50),
                                            out consumo_stimato_impostazione_ float,
								            out energia_media_prodotta float
										)
begin
-- blocco di declare
	declare energia_media_prodotta float default '0';
    declare consumo_stimato_impostazione_ float default 0;
    
-- corpo della procedure
-- calcolo la media di energia prodotta per giorno nel periodo in cui facciamo l'impostazione clima
	select (D.EnergiaTotaleProdotta)/timestampdiff(day,_fine,_inizio) into energia_media_prodotta
    from 
    (
		select sum(c.Valore) as EnergiaTotaleProdotta
		from Contatore c
        natural join FasciaOraria FO
        where c.Data between date(_inizio) and date(_fine)
    )as D;
    
    -- calcolo il consumo relativo all'impostazione clima richiesta usando la function 
    set consumo_stimato_impostazione_ = ConsumoClima(_cod_climatizzatore,_nome_utente,_inizio,_fine);
    
   end $$