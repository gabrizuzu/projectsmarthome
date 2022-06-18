# SET FOREIGN_KEY_CHECKS = 0;
drop database if exists Smarthome;
create database Smarthome;
use Smarthome;

create table Account ( 
    NomeUtente varchar (50) primary key,  
    Password varchar(50) not null, 
    DomandaSicurezza varchar(50) not null,  
    RispostaSicurezza varchar(50) not null
)engine = InnoDB default charset = latin1; 


create table Utente ( 
    CodFiscale varchar(16) primary key,  
    Nome varchar(50) not null, 
    Cognome varchar(50) not null, 
    DataNascita date not null, 
    DataIscrizione date not null,
    Telefono varchar(10) not null,
    Nickname varchar(50)not null,
    foreign key(Nickname) references Account(NomeUtente)
)engine = InnoDB default charset = latin1; 



CREATE TABLE Documento ( 
	NumDocumento varchar(50),
    Tipologia varchar(50),
    Scadenza date not null,
    Ente varchar(50) not null,
    Utente varchar(50)not null,
    primary key(Tipologia, NumDocumento), 
    foreign key (Utente) references Utente(CodFiscale)
	
)ENGINE = InnoDB DEFAULT CHARSET = latin1; 

CREATE TABLE GestoreCentrale( 
	NickName varchar(50),
    TimestampInizio timestamp,
    TimestampFine timestamp not null,
    PartenzaDifferita tinyint not null check (PartenzaDifferita in (0 , 1)), -- 0 si 1 no
    DataRegistro date not null,
    Fascia int not null,
    primary key(NickName, TimestampInizio),
    foreign key(NickName) references Account(NomeUtente)
    
)ENGINE = InnoDB DEFAULT CHARSET = latin1; 

CREATE TABLE Interazione( 
	Nickname varchar(50),
    Inizio timestamp,
    primary key (Nickname, Inizio),
    foreign key (Nickname) references Account(NomeUtente),
    foreign key (Nickname, Inizio) references GestoreCentrale(NickName, TimestampInizio)
)ENGINE = InnoDB DEFAULT CHARSET = latin1; 

create table Stanza ( 
    CodStanza int primary key, 
    Nome varchar(50) not null, 
    Larghezza double not null, 
    Lunghezza double not null, 
    Altezza double not null, 
    Piano tinyint not null
)engine = InnoDB default charset = latin1; 

create table Porta(
	CodPorta int primary key,
    TipoPorta varchar(10) check (TipoPorta in ('Interna','Esterna')),
    Ubicazione int not null,
    foreign key (Ubicazione) references Stanza(CodStanza)
) engine = InnoDB default charset = latin1; 

create table Finestra ( 
    CodiceFinestra int auto_increment primary key, 
    PuntoCardinale varchar(2) check (PuntoCardinale in ('N', 'NE', 'NW', 'S', 'SE', 'SW', 'E', 'W')), 
    Ubicazione int not null, 
    foreign key (Ubicazione) references Stanza(CodStanza) 
)engine = InnoDB default charset = latin1; 

create table PortaFinestra(
	CodPortaFinestra int auto_increment primary key,
    PuntoCardinale varchar(2) check (PuntoCardinale in ('N', 'NE', 'NW', 'S', 'SE', 'SW', 'E', 'W')), 
    Ubicazione int not null, 
    foreign key (Ubicazione) references Stanza(CodStanza) 
    )engine = InnoDB default charset = latin1; 
    
 create table Dispositivo (
    CodiceDispositivo INT AUTO_INCREMENT PRIMARY KEY,
    Nome varchar(50) not null,
    TipoConsumo varchar(10) check (TipoConsumo in('Fisso', 'Variabile', 'Ciclo')),
    Ubicazione int not null,
    foreign key(Ubicazione) references Stanza(CodStanza)
)  ENGINE=InnoDB DEFAULT CHARSET=latin1;   

create table ImpostazioniDispositivo (
	NickName varchar(50) not null,
    Inizio timestamp not null,
    Dispositivo int,
    PotenzaMedia double not null,
    ConsumoDispositivo int,
    primary key(NickName, Dispositivo, Inizio),
    foreign key (NickName, Inizio) references GestoreCentrale(NickName, TimestampInizio),
	foreign key (Dispositivo) references Dispositivo(CodiceDispositivo)
)  ENGINE=InnoDB DEFAULT CHARSET=latin1;



create table SmartPlug (
    CodiceSmartPlug INT AUTO_INCREMENT PRIMARY KEY,
    Dispositivo int not null,
    foreign key (Dispositivo) references Dispositivo (CodiceDispositivo)
)  ENGINE=InnoDB DEFAULT CHARSET=latin1;

create table Programma (
    CodProgramma INT AUTO_INCREMENT PRIMARY KEY,
    Durata time not null,
    LivelloConsumoEnergetico int not null,
    Dispositivo int not null,
    foreign key (Dispositivo)
        references Dispositivo (CodiceDispositivo)
)  ENGINE=InnoDB DEFAULT CHARSET=latin1;


create table EfficienzaEnergetica(
	Tempo timestamp,
    Ubicazione int,
    TemperaturaIN double,
    TemperaturaOUT double,
    EnergiaNecessaria double not null,
    primary key (Tempo,Ubicazione),
    foreign key(Ubicazione) references Stanza (CodStanza)
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

create table Climatizzatore (
    CodClimatizzatore int auto_increment primary key,
    Tipologia varchar(50) not null,
    PotenzaMedia double not null,
    Ubicazione int not null,
    foreign key (Ubicazione)
        references Stanza (CodStanza)
)  ENGINE=InnoDB DEFAULT CHARSET=latin1;

create table ImpostazioneClima (
    Climatizzatore int not null,
    NickName varchar(50),
    Inizio timestamp not null,
    Temperatura double check (Temperatura between 16 and 30),
    Umidità double,
    ConsumoClima int,
    primary key (Climatizzatore , Nickname, Inizio),
    foreign key (Climatizzatore) references Climatizzatore(CodClimatizzatore),
    foreign key (NickName, Inizio)references GestoreCentrale(NickName, TimestampInizio)

)  ENGINE=InnoDB DEFAULT CHARSET=latin1;

create table Ricorsione(
    CodRicorsione int,
    Frequenza int not null, -- espressa in giorni
    DataInizioRicorsione date not null,
    OraInizioRicorsione time,
    Climatizzatore int not null,
    Inizio timestamp not null,
    NickName varchar(50) not null,
    primary key (CodRicorsione,Climatizzatore , Nickname, Inizio),
    foreign key (Climatizzatore , Nickname, Inizio) references ImpostazioneClima(Climatizzatore ,Nickname, Inizio)
)  ENGINE=InnoDB DEFAULT CHARSET=latin1;



create table Luce (
    CodLuce int auto_increment primary key,
    Nome varchar(50) not null,
    Ubicazione int not null,
    foreign key (Ubicazione)
        references Stanza (CodStanza)
)  ENGINE=InnoDB DEFAULT CHARSET=latin1;

create table RegolazioneLuce(
	Luce int,
    Nickname varchar(50),
    Inizio timestamp,
    Intensità double not null,
    TempColore int not null,
    ConsumoLuce  int,
    primary key (Luce , Nickname ,Inizio),
    foreign key (Luce) references Luce(CodLuce),
    foreign key (Nickname, Inizio) references GestoreCentrale(Nickname,TimestampInizio)
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

create table FasciaOraria( 
	CodFascia int auto_increment primary key,
    Nome varchar(10) not null,
	OraInizio time not null, 
    OraFine time not null, 
    PrezzoAcquistoPerH double not null,
    PrezzoVenditaPerH double not null
)  ENGINE=InnoDB DEFAULT CHARSET=latin1; 

create table Contatore(
	Data date,
	CodFascia int,
	Valore double,
	primary key(Data, CodFascia),
    foreign key (CodFascia)
		references FasciaOraria(CodFascia)
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

create table Suggerimento (
    CodSuggerimento int auto_increment primary key,
    Dispositivo int not null default 1,
    Risposta tinyint check (Risposta in (0, 1)),
    Testo varchar(255),
    DataRegistro date not null default '2022-03-21 10:33:00',
    Fascia int not null default 1,
	foreign key (Dispositivo)
		references Dispositivo(CodiceDispositivo),
	foreign key (Fascia, DataRegistro)
		references Contatore(CodFascia, Data)
	
)  ENGINE=InnoDB DEFAULT CHARSET=latin1;


create table Batteria( 
	CodBatteria int auto_increment primary key, 
	Capacita double not null,
    EnergiaImmagazzinata double default 0,
    DataRegistro  date not null,
    Fascia int not null,
	foreign key (Fascia, DataRegistro)
		references Contatore(CodFascia,Data)
)  ENGINE=InnoDB DEFAULT CHARSET=latin1; 

 create table Sorgente(
	Timestamp timestamp primary key,
    Produzione double
)ENGINE=InnoDB DEFAULT CHARSET=latin1; 

create table Immissione(
	TimestampSorgente timestamp,
    DataRegistro date,
    Fascia int,
    primary key(TimestampSorgente, DataRegistro, Fascia),
    foreign key (TimestampSorgente) references Sorgente(Timestamp),
	foreign key (Fascia, DataRegistro)
		references Contatore(CodFascia,Data)
)ENGINE=InnoDB DEFAULT CHARSET=latin1; 


# creazione trigger
-- il seguente trigger ha la funzione di evitare che le fascie orarie si sovvrappongano
drop trigger if exists controllo_fascia;
delimiter $$
create trigger controllo_fascia
before insert on FasciaOraria
for each row
	begin
		if exists (
        select *
        from FasciaOraria
        where (OraInizio < new.OraInizio and OraFine > new.OraInizio)
        or (OraInizio < new.OraFine and OraFine > new.OraFine)
		) then
        signal sqlstate '45000' set message_text = 'Fascia non adatta';
        end if;
    
    end $$
delimiter ;
-- il seguente trigger ha la funzione di assicurare che la DataRicorsione sia successiva al suo timestamp
drop trigger if exists controllo_ricorsione
delimiter $$
create trigger controllo_ricorsione
before insert on Ricorsione
for each row
	begin
    if (new.DataInizioRicorsione < current_date) then
    signal sqlstate '45000' set message_text = 'La DataRicorsione deve essere impostata ad una data futura';
        end if;
    end $$
delimiter ;

-- la funzione calcola approssivativamente il consumo di un iterazione con dispositivo dove il timestampFine non è più null
-- il risultato è in kWh
drop function if exists ConsumoDispositivo;
delimiter $$
create function ConsumoDispositivo (potenza double, inizio timestamp, fine timestamp)
returns double deterministic
begin
	declare consumo double default 0;
    set consumo=(potenza * timestampdiff(hour,fine,inizio))/1000;
    return consumo;
end $$
delimiter ;

-- il seguente trigger garantisce che quando viene inserita una nuova impostazione dispositivo ad un dispositivo già impostato nel quale timestampfine è null, 
-- ne imposta il timestampfine al current_timestamp (cioè interrompe l'impostazione precedente allo stesso dispositivo) e ne calcola il consumo

drop trigger if exists fine_impostazione_dispositivo
delimiter $$
create trigger fine_impostazione_dispositivo
before insert on ImpostazioniDispositivo
for each row
	begin
    declare utente_ varchar(50) default '';
    declare inizio_ timestamp;
    declare potenza_ double;
    
		select GC.Nickname, GC.TimestampInizio, ID.PotenzaMedia into utente_, inizio_, potenza_
        from ImpostazioniDispositivo ID
        inner join GestoreCentrale GC on ID.Inizio = GC.TimestampInizio
        and ID.Nickname = GC.Nickname
        where ID.Dispositivo = new.Dispositivo
        and GC.TimestampFine is null;
        
	update GestoreCentrale
    set TimestampFine = current_timestamp
    where TimestampInizio = inizio_ and Nickname = utente_;
    
   
		
    end $$
delimiter ;

-- il seguente trigger aggirona l'attributo consumo dispositivo
drop trigger if exists Aggiorna_consumo_dispositivo
delimiter $$
create trigger Aggiorna_consumo_dispositivo
after update on GestoreCentrale
for each row
begin
    declare utente_ varchar(50) default '';
    declare inizio_ timestamp;
    declare potenza_ double;
    
		select GC.Nickname, GC.TimestampInizio, ID.PotenzaMedia into utente_, inizio_, potenza_
        from ImpostazioniDispositivo ID
        inner join GestoreCentrale GC on ID.Inizio = GC.TimestampInizio
        and ID.Nickname = GC.Nickname
        where GC.Nickname = new.Nickname
        and GC.TimestampInizio= new.TimestampInizio;
        
	update ImpostazioniDispositivo
    set ConsumoDispositivo = ConsumoDispositivo(potenza_,inizio_,current_timestamp)
	where Inizio = inizio_ and Nickname = utente_;

end $$
delimiter ;

-- la funzione calcola approssivativamente il consumo di un iterazione di illuminazione dove il timestampFine non è più null
-- approssimiamo il calcolo del consumo usando la legge P=I^2*R, dove I è intesità e R la resistenza che stiamiamo uguale per tutti i dispositivi di illuminazione (45 ohm)
-- il risultato è in kWh
drop function if exists ConsumoLuce;
delimiter $$
create function ConsumoLuce (intensità double, inizio timestamp, fine timestamp)
returns double deterministic
begin
	declare consumo double default 0;
    declare resistenza double default 45;
    set consumo=(intensità * intensità * resistenza * timestampdiff(hour,fine,inizio))/1000;
    return consumo;
end $$
delimiter ;

-- il seguente trigger garantisce che quando viene inserita una nuova regolazione luce ad una luce già impostata nel quale timestampfine è null, 
-- ne imposta il timestampfine al current_timestamp (cioè interrompe l'impostazione precedente alla stessa luce)

drop trigger if exists fine_regolazione_luce
delimiter $$
create trigger fine_regolazione_luce
before insert on RegolazioneLuce
for each row
	begin
    declare utente_ varchar(50) default '';
    declare inizio_ timestamp;
    declare intensità_ double default 0;
    
		select GC.Nickname, GC.TimestampInizio, RL.Intensità into utente_, inizio_,intensità_
        from RegolazioneLuce RL
        inner join GestoreCentrale GC on RL.Inizio = GC.TimestampInizio
        and RL.Nickname = GC.Nickname
        where RL.Luce = new.Luce
        and GC.TimestampFine is null;
        
	update GestoreCentrale
    set TimestampFine = current_timestamp
    where TimestampInizio = inizio_ and Nickname= utente_;
    
   
		
    end $$
delimiter ;

-- il seguente trigger aggirona l'attributo consumo luce
drop trigger if exists Aggiorna_consumo_luce
delimiter $$
create trigger Aggiorna_consumo_luce
after update on GestoreCentrale
for each row
begin
	declare utente_ varchar(50) default '';
    declare inizio_ timestamp;
    declare intensità_ double default 0;
    
		select GC.Nickname, GC.TimestampInizio, RL.Intensità into utente_, inizio_,intensità_
        from RegolazioneLuce RL
        inner join GestoreCentrale GC on RL.Inizio = GC.TimestampInizio
        and RL.Nickname = GC.Nickname
        where GC.Nickname = new.Nickname
        and GC.TimestampInizio= new.TimestampInizio;
        
	update RegolazioneLuce
    set ConsumoLuce= ConsumoLuce(potenza_,inizio_,current_timestamp)
	where Inizio = new.TimestampInizio and Nickname = new.Nickname;

end $$
delimiter ;

-- la funzione calcola approssivativamente il consumo di un iterazione di clima dove il timestampFine non è più null
-- approssimiamo il calcolo del consumo ricavando l'energiaNecessaria per cambiare la temperatura di un grado e moltiplicarlo per la differenza che c'è tra la temperatura attuale e quella richiesta
-- il risultato è in kWh
drop function if exists ConsumoClima;
delimiter $$
create function ConsumoClima ( climatizzatore_ int, utente_ varchar(50),inizio_ timestamp,fine_ timestamp)
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
-- il seguente trigger garantisce che quando viene inserita una nuova impostazione clima ad un climatizzatore già impostato nel quale timestampfine è null, 
-- ne imposta il timestampfine al current_timestamp (cioè interrompe l'impostazione precedente allo stesso dispositivo)

drop trigger if exists fine_impostazione_climatizzatore
delimiter $$
create trigger fine_impostazione_climatizzatore
before insert on ImpostazioneClima
for each row
	begin
    declare utente_ varchar(50) default '';
    declare inizio_ timestamp;
    declare climatizzatore_ int;
    
		select GC.Nickname, GC.TimestampInizio, IC.Climatizzatore into utente_, inizio_, climatizzatore_
        from ImpostazioneClima IC
        inner join GestoreCentrale GC on IC.Inizio = GC.TimestampInizio
        and IC.Nickname = GC.Nickname
        where IC.Climatizzatore = new.Climatizzatore
        and GC.TimestampFine is null;
        
	update GestoreCentrale
    set TimestampFine = current_timestamp
    where TimestampInizio = inizio_ and Nickname = utente_;
	
    
    
    end $$
delimiter ;

-- il seguente trigger aggirona l'attributo consumo clima
drop trigger if exists Aggiorna_consumo_clima
delimiter $$
create trigger Aggiorna_consumo_clima
after update on GestoreCentrale
for each row
begin
	declare utente_ varchar(50) default '';
    declare inizio_ timestamp;
    declare climatizzatore_ int;
    
		select GC.Nickname, GC.TimestampInizio, IC.Climatizzatore into utente_, inizio_, climatizzatore_
        from ImpostazioneClima IC
        inner join GestoreCentrale GC on IC.Inizio = GC.TimestampInizio
        and IC.Account = GC.Utente
        where GC.Nickname=new.Nickname
        and GC.TimestampInizio=new.TimestampInizio;

    update ImpostazioneClima
    set ConsumoClima = ConsumoClima(climatizzatore_,utente_,inizio_,current_timestamp)
    where Nickname=utente_ and Inizio=inizio_;

end $$
delimiter ;
