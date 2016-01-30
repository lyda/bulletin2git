9 From:	SMTP%"BULLETIN@PFC.MIT.EDU" 19-AUG-1994 17:29:51.67  To:	EVERHART CC:	 Subj:	NEWS.COM  + Date: Fri, 19 Aug 1994 17:26:26 -0400 (EDT)  From: BULLETIN@PFC.MIT.EDU To:   EVERHART@arisia.gce.com / Message-Id: <940819172626.21438991@PFC.MIT.EDU>  Subject: NEWS.COM   
 $set nover $copy/log sys$input NEWS.ALT $deck   ) From: ccs@aber.ac.uk (Christopher Samuel)  Date:  2-OCT-1992  11:36:37 5 Description: Creating a new "alt" group -- guidelines    Archive-name: alt-config-guide Version: 1.2+ Last-modified: Wed Sep  2 16:31:55 GMT 1992          0 		Guidelines for the creation of an "alt" group.   F There are no rules or guidelines for creation of "alt" groups, HoweverH there does appear to be an established procedure which follows.  First a/ quick bit of common-sense on choosing the name:    G When choosing a name for a group please note the only commandment: Thou G shalt not choose a group name which may cause network harm or harm to a  local machine.                Examples:    ,           alt.fan.enya.puke.puke.pukeSender:   >           [preceding line to Sender had <CR> deleted; also the>            trailing : can cause problems in some news systems]   ?           alt.verylonggroupnamethathasadirectorylongerthanmost\ /           machinessupportsotherehaha.very.funny    >           alt.[insert300charactershere].very.long.group.name.\$           that.is.too.big.for.newsrc   2           alt.*.this.name.has.bad.characters.in.it   $           alt..double.dot.group.name       		Now the Guidelines:  		-------------------    >        1) Propose a new alt group in alt.config.  The proposalD           should include a charter or purpose for the new group, andF           some demonstration of the need for the group.  It is best toE           make it clear in your subject line that you are proposing a H           new group. Be prepared to explain why an existing group cannotH           be used for this purpose, and why the group should be in "alt"@           rather than in one of the mainstream hierarchies (like>           "rec", "sci", etc.).  Avoiding the complexity of the@           mainstream group creation procedure is not a very goodD           reason, groups should not be created in "alt" just becauseD           it's easier.  Don't forget that mainstream groups can alsoE           be created by the "trial" mechanism.  Many sites do not get E           any alt groups, so if you are proposing a serious group, it @           is worth the effort to try to get it into a mainstream           hierarchy.   C        2) See what the alt.net.opinion of the new group is.  Wait a D           few days for replies to trickle in from the far corners ofD           the net.  If the consensus (however you determine that) isC           that the group should be created, then proceed to step 3.    A           (these first two steps are often ignored, which usually 2           leads to unpleasantness in step 4 below)   ?        3) Post a "newgroup" control message.  If you don't know E           how to do this, check with your news administrator.  If you B           ARE your news administrator, and you can't figure it out<           from the documentation you have (or don't have anyE           documentation) send me mail and I will help you.  NOTE that >           many sites do NOT automatically honor "newgroup" andF           "rmgroup" control messages, the news software at these sitesE           will send mail to the news administrator, who will evaluate E           your request and decide whether or not to create the group. A           It may take a couple of days for the control message to >           propagate and be acted upon, so don't expect instantE           availability of the new group, particularly if you post the ,           control message on a Friday night.   @           NB:	It is good manners to put a description of the new<           	newsgroup into the newgroup message, along with a?           	one-line description suitable for inclusion into the            	newsgroups file.    <        4) Let the individual site news administrators decide@           whether to honor your "newgroup" message.  Most adminsA           prefer that the message come from a verifiable account, ?           messages which are obviously forged, or have not been A           discussed in alt.config and contain no explanation will D           probably not be honored by many sites.  Persons opposed toE           the group, or admins who feel that the newgroup message was F           a forgery may send out "rmgroup" messages to try to sabotageD           the group.  It may take several iterations of this processD           to firmly establish the new group.  It has been humorouslyF           suggested that only alt groups which get 100 more "newgroup"B           than "rmgroup" messages should be established.  However,C           these "rmgroup wars" are annoying to news administrators, E           and reduce the overall acceptance (and distribution) of the A           "alt" hierarchy.  This is the reason that steps 1 and 2            above are important.      F This may sound like a lot of rigamarole, and it is.  The purpose is toH discourage creation of alt groups that might be better off as mainstream2 groups, or that might be better of left uncreated.   E Don't take this all too seriously, though.  The "alt" net is the last D remaining refuge away from the control freaks, namespace purists and? net.cops (like myself) that maintain and enforce the mainstream  newsgroup guidelines.    I There is still some room for spontaneity out here on the "alt" frontier.  I Successful groups have been created without following these suggestions.  @ Almost any non-forged, serious newgroup message will at least beH considered by most news admins.  Some groups have been created just on a> whim.  The concept behind the group better be good (or a least entertaining), though!   H [ If you want more information on mainstream group creation see the postH   "How to Create a New Newsgroup" posted to news.answers, news.admin and   news.groups. ]    --  K  Christopher Samuel, c/o Computer Unit, UCW Aberystwyth, Aberystwyth, WALES J   RFC: ccs@aber.ac.uk   UUCP: *!mcsun!uknet!aber!ccs   JNT: ccs@uk.ac.aberA           Deddf Iaith Newydd i Gymru | New Language Act for Wales   ) From: ccs@aber.ac.uk (Christopher Samuel)  Date:  2-OCT-1992  11:36:37 5 Description: Creating a new "alt" group -- guidelines    Archive-name: alt-config-guide Version: 1.2+ Last-modified: Wed Sep  2 16:31:55 GMT 1992          0 		Guidelines for the creation of an "alt" group.   F There are no rules or guidelines for creation of "alt" groups, HoweverH there does appear to be an established procedure which follows.  First a/ quick bit of common-sense on choosing the name:    G When choosing a name for a group please note the only commandment: Thou G shalt not choose a group name which may cause network harm or harm to a  local machine.                Examples:    ,           alt.fan.enya.puke.puke.pukeSender:   >           [preceding line to Sender had <CR> deleted; also the>            trailing : can cause problems in some news systems]   ?           alt.verylonggroupnamethathasadirectorylongerthanmost\ /           machinessupportsotherehaha.very.funny    >           alt.[insert300charactershere].very.long.group.name.\$           that.is.too.big.for.newsrc   2           alt.*.this.name.has.bad.characters.in.it   $           alt..double.dot.group.name       		Now the Guidelines:  		-------------------    >        1) Propose a new alt group in alt.config.  The proposalD           should include a charter or purpose for the new group, andF           some demonstration of the need for the group.  It is best toE           make it clear in your subject line that you are proposing a H           new group. Be prepared to explain why an existing group cannotH           be used for this purpose, and why the group should be in "alt"@           rather than in one of the mainstream hierarchies (like>           "rec", "sci", etc.).  Avoiding the complexity of the@           mainstream group creation procedure is not a very goodD           reason, groups should not be created in "alt" just becauseD           it's easier.  Don't forget that mainstream groups can alsoE           be created by the "trial" mechanism.  Many sites do not get.E           any alt groups, so if you are proposing a serious group, itb@           is worth the effort to try to get it into a mainstream           hierarchy.  aC        2) See what the alt.net.opinion of the new group is.  Wait a1D           few days for replies to trickle in from the far corners ofD           the net.  If the consensus (however you determine that) isC           that the group should be created, then proceed to step 3.b  nA           (these first two steps are often ignored, which usually-2           leads to unpleasantness in step 4 below)  f?        3) Post a "newgroup" control message.  If you don't knowoE           how to do this, check with your news administrator.  If younB           ARE your news administrator, and you can't figure it out<           from the documentation you have (or don't have anyE           documentation) send me mail and I will help you.  NOTE thatw>           many sites do NOT automatically honor "newgroup" andF           "rmgroup" control messages, the news software at these sitesE           will send mail to the news administrator, who will evaluate E           your request and decide whether or not to create the group.rA           It may take a couple of days for the control message too>           propagate and be acted upon, so don't expect instantE           availability of the new group, particularly if you post thee,           control message on a Friday night.   @           NB:	It is good manners to put a description of the new<           	newsgroup into the newgroup message, along with a?           	one-line description suitable for inclusion into thei           	newsgroups file.   u<        4) Let the individual site news administrators decide@           whether to honor your "newgroup" message.  Most adminsA           prefer that the message come from a verifiable account, ?           messages which are obviously forged, or have not been A           discussed in alt.config and contain no explanation will D           probably not be honored by many sites.  Persons opposed toE           the group, or admins who feel that the newgroup message was F           a forgery may send out "rmgroup" messages to try to sabotageD           the group.  It may take several iterations of this processD           to firmly establish the new group.  It has been humorouslyF           suggested that only alt groups which get 100 more "newgroup"B           than "rmgroup" messages should be established.  However,C           these "rmgroup wars" are annoying to news administrators,oE           and reduce the overall acceptance (and distribution) of thedA           "alt" hierarchy.  This is the reason that steps 1 and 2)           above are important.  o  oF This may sound like a lot of rigamarole, and it is.  The purpose is toH discourage creation of alt groups that might be better off as mainstream2 groups, or that might be better of left uncreated.  iE Don't take this all too seriously, though.  The "alt" net is the lastnD remaining refuge away from the control freaks, namespace purists and? net.cops (like myself) that maintain and enforce the mainstreamh newsgroup guidelines.e  tI There is still some room for spontaneity out here on the "alt" frontier.  I Successful groups have been created without following these suggestions.  @ Almost any non-forged, serious newgroup message will at least beH considered by most news admins.  Some groups have been created just on a> whim.  The concept behind the group better be good (or a least entertaining), though!  FH [ If you want more information on mainstream group creation see the postH   "How to Create a New Newsgroup" posted to news.answers, news.admin and   news.groups. ]  c -- oK  Christopher Samuel, c/o Computer Unit, UCW Aberystwyth, Aberystwyth, WALES4J   RFC: ccs@aber.ac.uk   UUCP: *!mcsun!uknet!aber!ccs   JNT: ccs@uk.ac.aberA           Deddf Iaith Newydd i Gymru | New Language Act for Walesh $eod g $copy/log sys$input NEWS.CREATE  $deck * From: tale@uunet.uu.net (David C Lawrence) Date: 19-OCT-1992  00:15:29c1 Description: How to Create a New Usenet Newsgroup   ' Archive-name: creating-newsgroups/part1 1 Original-author: woods@ncar.ucar.edu (Greg Woods) > Last-change: 23 Sep 1992 by spaf@cs.purdue.edu (Gene Spafford)   ) 				 GUIDELINES FOR USENET GROUP CREATIONa  a  REQUIREMENTS FOR GROUP CREATION:   C    These are guidelines that have been generally agreed upon across H USENET as appropriate for following in the creating of new newsgroups inD the "standard" USENET newsgroup hierarchy. They are NOT intended as I guidelines for setting USENET policy other than group creations, and they H are not intended to apply to "alternate" or local news hierarchies. The H part of the namespace affected is comp, news, sci, misc, soc, talk, rec,D which are the most widely-distributed areas of the USENET hierarchy.A    Any group creation request which follows these guidelines to aaC successful result should be honored, and any request which fails touF follow these procedures or to obtain a successful result from doing soA should be dropped, except under extraordinary circumstances.  TheeG reason these are called guidelines and not absolute rules is that it islE not possible to predict in advance what "extraordinary circumstances"  are or how they might arise.M    It should be pointed out here that, as always, the decision whether or notaM to create a newsgroup on a given machine rests with the administrator of thatrG machine. These guidelines are intended merely as an aid in making thoses
 decisions.  t  j The Discussion  eN 1) A request for discussion on creation of a new newsgroup should be posted toL    news.announce.newgroups, and also to any other groups or mailing lists atM    all related to the proposed topic if desired.  The group is moderated, andgJ    the Followup-to: header will be set so that the actual discussion takesN    place only in news.groups.  Users on sites which have difficulty posting toM    moderated groups may mail submissions intended for news.announce.newgroupsa&    to announce-newgroups@uunet.uu.net.  aE    The article should be cross-posted among the newsgroups, including O    news.announce.newgroups, rather than posted as separate articles.  Note thateL    standard behaviour for posting software is to not present the articles inO    any groups when cross-posted to a moderated group; the moderator will handlep    that for you.  sN 2) The name and charter of the proposed group and whether it will be moderatedM    or unmoderated (and if the former, who the moderator(s) will be) should beoO    determined during the discussion period. If there is no general agreement onwL    these points among the proponents of a new group at the end of 30 days ofK    discussion, the discussion should be taken offline (into mail instead ofeD    news.groups) and the proponents should iron out the details amongM    themselves.  Once that is done, a new, more specific proposal may be made,g!    going back to step 1) above.  p  sG 3) Group advocates seeking help in choosing a name to suit the proposedlL    charter, or looking for any other guidance in the creation procedure, canR    send a message to group-advice@uunet.uu.net; a few seasoned news administrators&    are available through this address.  - The Vote   M 1) AFTER the discussion period, if it has been determined that a new group isuF    really desired, a name and charter are agreed upon, and it has beenD    determined whether the group will be moderated and if so who willM    moderate it, a call for votes may be posted to news.announce.newgroups andrM    any other groups or mailing lists that the original request for discussion G    might have been posted to. There should be minimal delay between the D    end of the discussion period and the issuing of a call for votes.G    The call for votes should include clear instructions for how to castnF    a vote. It must be as clearly explained and as easy to do to cast aE    vote for creation as against it, and vice versa.  It is explicitlypF    permitted to set up two separate addresses to mail yes and no votesF    to provided that they are on the same machine, to set up an addressG    different than that the article was posted from to mail votes to, oreF    to just accept replies to the call for votes article, as long as itE    is clearly and explicitly stated in the call for votes article hownC    to cast a vote.  If two addresses are used for a vote, the replyeB    address must process and accept both yes and no votes OR reject    them both.t  tI 2) The voting period should last for at least 21 days and no more than 31lJ    days, no matter what the preliminary results of the vote are. The exactH    date that the voting period will end should be stated in the call forJ    votes. Only votes that arrive on the vote-taker's machine prior to this    date will be counted.  rL 3) A couple of repeats of the call for votes may be posted during the vote, F    provided that they contain similar clear, unbiased instructions forJ    casting a vote as the original, and provided that it is really a repeatJ    of the call for votes on the SAME proposal (see #5 below). Partial voteG    results should NOT be included; only a statement of the specific newaL    group proposal, that a vote is in progress on it, and how to cast a vote.J    It is permitted to post a "mass acknowledgement" in which all the namesH    of those from whom votes have been received are posted, as long as noH    indication is made of which way anybody voted until the voting period    is officially over.  nJ 4) ONLY votes MAILED to the vote-taker will count. Votes posted to the netJ    for any reason (including inability to get mail to the vote-taker) and J    proxy votes (such as having a mailing list maintainer claim a vote for 0    each member of the list) will not be counted.  oI 5) Votes may not be transferred to other, similar proposals. A vote shallsM    count only for the EXACT proposal that it is a response to. In particular,rK    a vote for or against a newsgroup under one name shall NOT be counted asaF    a vote for or against a newsgroup with a different name or charter,I    a different moderated/unmoderated status or (if moderated) a differentg"    moderator or set of moderators.  tE 6) Votes MUST be explicit; they should be of the form "I vote for thekB    group foo.bar as proposed" or "I vote against the group foo.barG    as proposed". The wording doesn't have to be exact, it just needs to F    be unambiguous. In particular, statements of the form "I would voteC    for this group if..." should be considered comments only and nota    counted as votes.  aM 7) A vote should be run only for a single group proposal.  Attempts to create N    multiple groups should be handled by running multiple parallel votes rather-    than one vote to create all of the groups.   o
 The Result  ,G 1) At the completion of the voting period, the vote taker must post thegM    vote tally and the E-mail addresses and (if available) names of the voterseL    received to news.announce.newgroups and any other groups or mailing listsL    to which the original call for votes was posted. The tally should includeG    a statement of which way each voter voted so that the results can bed    verified.  rI 2) AFTER the vote result is posted, there will be a 5 day waiting period,c8    beginning when the voting results actually appear in F    news.announce.newgroups, during which the net will have a chance to@    correct any errors in the voter list or the voting procedure.  dO 3) AFTER the waiting period, and if there were no serious objections that mighttK    invalidate the vote, and if 100 more valid YES/create votes are receivedtK    than NO/don't create AND at least 2/3 of the total number of valid voteseM    received are in favor of creation, a newgroup control message may be sent tO    out.  If the 100 vote margin or 2/3 percentage is not met, the group should e    not be created.  kM 4) The newgroup message will be sent by the news.announce.newgroups moderatoreN    at the end of the waiting period of a successful vote.  If the new group isO    moderated, the vote-taker should send a message during the waiting period to T    Gene Spafford <spaf@cs.purdue.edu> and David C. Lawrence <tale@uunet.uu.net> withK    both the moderator's contact address and the group's submission address.a  rH 5) A proposal which has failed under point (3) above should not again beK    brought up for discussion until at least six months have passed from thepN    close of the vote.  This limitation does not apply to proposals which never    went to vote.  U $eod e# $copy/log sys$input NEWS.MODERATORSd $deck ( comp.ai.nlang-know-rep		nl-kr@cs.rpi.edu$ comp.ai.vision			vision-list@ads.com& comp.archives			comp-archives@msen.com$ comp.binaries.acorn		cba@acorn.co.nz' comp.binaries.amiga		amiga@uunet.uu.net,3 comp.binaries.atari.st		atari-binaries@hyperion.comt) comp.binaries.ibm.pc		cbip@cs.ulowell.eduA4 comp.binaries.mac		macintosh%felix.uucp@uunet.uu.net* comp.binaries.os2		os2bin@csd4.csd.uwm.edu7 comp.bugs.4bsd.ucb-fixes	ucb-fixes@okeeffe.berkeley.edue/ comp.compilers			compilers@iecc.cambridge.ma.us ' comp.dcom.telecom		telecom@eecs.nwu.edun comp.doc			comp-doc@ucsd.edu: comp.doc.techreports		compdoc-techreports@ftp.cse.ucsc.edu3 comp.graphics.research		graphics@scri1.scri.fsu.edut, comp.internet.library		library@axon.cwru.edu' comp.lang.sigplan		sigplan@bellcore.come1 comp.laser-printers		laser-lovers@brillig.umd.eduo$ comp.mail.maps			uucpmap@rutgers.edu& comp.newprod			newprod@chg.mcd.mot.com" comp.org.eff.news		effnews@eff.org$ comp.org.fidonet		pozar@hop.toad.com9 comp.os.ms-windows.announce	infidel+win-announce@pitt.edus& comp.os.research		osr@ftp.cse.ucsc.edu, comp.parallel			hypercube@hubcap.clemson.edu" comp.patents			patents@cs.su.oz.au9 comp.protocols.kermit		info-kermit@watsun.cc.columbia.edui) comp.research.japan		japan@cs.arizona.eduF comp.risks			risks@csl.sri.com1 comp.simulation			simulation@uflorida.cis.ufl.edun( comp.society			socicom@auvm.american.edu/ comp.society.cu-digest		tk0jut2@mvs.cso.niu.edul1 comp.society.folklore		folklore@snark.thyrsus.com 0 comp.society.privacy		comp-privacy@pica.army.mil8 comp.sources.3b1		comp-sources-3b1@galaxia.network23.com# comp.sources.acorn		cba@acorn.co.nza& comp.sources.amiga		amiga@uunet.uu.net) comp.sources.apple2		jac@paul.rutgers.edun1 comp.sources.atari.st		atari-sources@hyperion.comy* comp.sources.games		games@saab.cna.tek.com& comp.sources.hp48		hp48@seq.uncwil.edu3 comp.sources.mac		macintosh%felix.uucp@uunet.uu.net , comp.sources.misc		sources-misc@uunet.uu.net- comp.sources.reviewed		csr@calvin.dgbt.doc.cao/ comp.sources.sun		sun-sources@topaz.rutgers.edue4 comp.sources.unix		unix-sources-moderator@pa.dec.com" comp.sources.x			x-sources@msi.com* comp.std.announce		klensin@infoods.mit.edu# comp.std.mumps			std-mumps@pfcs.comd% comp.std.unix			std-unix@uunet.uu.nete- comp.sys.acorn.announce		announce@acorn.co.ukn0 comp.sys.amiga.announce		announce@cs.ucdavis.edu= comp.sys.amiga.reviews		amiga-reviews-submissions@math.uh.edub1 comp.sys.concurrent		concurrent@bdcsys.suvl.ca.use4 comp.sys.ibm.pc.digest		info-ibmpc@simtel20.army.mil. comp.sys.m68k.pc		info-68k@ucbvax.berkeley.edu1 comp.sys.mac.announce		csma@rascal.ics.utexas.eduo4 comp.sys.mac.digest		info-mac@sumex-aim.stanford.edu1 comp.sys.next.announce		csn-announce@liveware.comh0 comp.sys.sun.announce		sun-announce@sunworld.com: comp.theory.info-retrieval	ir-l%uccvma.bitnet@berkeley.edu comp.virus			krvw@cert.org3 comp.windows.x.announce		xannounce@expo.lcs.mit.edur4 misc.activism.progressive	map@pencil.cs.missouri.edu/ misc.handicap			handicap@bunker.shel.isc-br.comc* misc.news.southasia		surekha@nyx.cs.du.edu- news.admin.technical		natech@zorch.sf-bay.orgs- news.announce.conferences	nac@tekbspa.tss.comd. news.announce.important		announce@stargate.com3 news.announce.newgroups		announce-newgroups@rpi.edu * news.announce.newusers		spaf@cs.purdue.edu# news.answers			news-answers@mit.edut- news.lists			news-lists-request@cs.purdue.edut' news.lists.ps-maps		reid@decwrl.dec.comg, rec.arts.cinema			cinema@zerkalo.harvard.edu. rec.arts.comics.info		info_comic@dartmouth.edu% rec.arts.erotica		erotica@telly.on.cat- rec.arts.movies.reviews		movies@mtgzy.att.coma2 rec.arts.sf.announce		sf-announce@zorch.sf-bay.org- rec.arts.sf.reviews		sf-reviews@presto.ig.com . rec.arts.startrek.info		trek-info@dweeb.fx.com4 rec.audio.high-end		info-high-audio@csd4.csd.uwm.edu- rec.food.recipes		recipes@mthvax.cs.miami.edut& rec.games.cyber			cyberrpg@veritas.comA rec.games.frp.announce		rg-frp-announce@magnus.acs.ohio-state.edue, rec.games.frp.archives		frp-archives@rpi.edu? rec.games.mud.announce		rgm-announce@glia.biostr.washington.edun$ rec.guns			magnum@flubber.cs.umd.edu$ rec.humor.funny			funny@clarinet.com+ rec.humor.oracle		oracle-mod@cs.indiana.edud) rec.hunting			hunting@osnome.che.wisc.edu " rec.mag.fsfnet			white@duvm.bitnet* rec.music.gaffa			love-hounds@uunet.uu.net0 rec.music.info			rec-music-info@ph.tn.tudelft.nl( rec.music.reviews		music_reviews@sco.com. rec.radio.broadcasting		rrb@airwaves.chi.il.us9 rec.sport.cricket.scores	cricket@power.eee.ndsu.nodak.eduh& sci.astro.hubble		sah@wfpc3.la.asu.edu- sci.math.research		sci-math-research@uiuc.edu  sci.med.aids			aids@cs.ucla.eduO# sci.military			military@att.att.come* sci.nanotech			nanotech@aramis.rutgers.edu1 sci.psychology.digest		psyc@phoenix.princeton.edu 1 sci.space.news			sci-space-news@news.arc.nasa.govn: sci.virtual-worlds		virtual-worlds@milton.u.washington.edu% soc.feminism			feminism@ncar.ucar.edui# soc.politics			poli-sci@rutgers.eduy* soc.politics.arms-d		arms-d@xx.lcs.mit.edu' soc.religion.bahai		srb@oneworld.wa.comh4 soc.religion.christian		christian@aramis.rutgers.edu% soc.religion.eastern		sre@cse.ogi.edue0 soc.religion.islam		religion-islam@ncar.ucar.edu+ alt.atheism.moderated		atheism@mantis.co.uka8 alt.binaries.pictures.fine-art.d	artcomp@uxa.ecn.bgu.edu@ alt.binaries.pictures.fine-art.digitized	artcomp@uxa.ecn.bgu.edu? alt.binaries.pictures.fine-art.graphics	artcomp@uxa.ecn.bgu.edu + alt.comp.acad-freedom.news	caf-news@eff.org  alt.dev.null			/dev/null% alt.gourmand			recipes@decwrl.dec.com  alt.hackers			/dev/nulln( alt.hindu			editor@rbhatnagar.csm.uc.edu7 alt.politics.democrats		news-submit@dc.clinton-gore.orgr> alt.politics.democrats.clinton	news-submit@dc.clinton-gore.org@ alt.politics.democrats.governors	news-submit@dc.clinton-gore.org< alt.politics.democrats.house	news-submit@dc.clinton-gore.org= alt.politics.democrats.senate	news-submit@dc.clinton-gore.orgi% alt.security.index		kyle@uunet.uu.net ( alt.society.ati			gzero@tronsbox.xei.com. alt.society.cu-digest		tk0jut2@mvs.cso.niu.edu$ alt.sources.index		kyle@uunet.uu.net) austin.eff			eff-austin-moderator@tic.comn* ba.announce			ba-announce@zorch.sf-bay.org; bionet.announce			biosci-announce-moderator@genbank.bio.nett? bionet.biology.computational	comp-bio-moderator@genbank.bio.net 7 bionet.molbio.ddbj.updates	ddbj-updates@genbank.bio.net ? bionet.molbio.embldatabank.updates	embl-updates@genbank.bio.neth2 bionet.molbio.genbank.updates	lear@genbank.bio.net9 bionet.software.sources		software-sources@genbank.bio.netr. bit.listserv.big-lan		big-req@suvm.acs.syr.edu1 bit.listserv.edtech		21765EDT%MSU@CUNYVM.CUNY.EDUu* bit.listserv.gaynet		gaynet@athena.mit.edu) bit.listserv.hellas		sda106@psuvm.psu.edue/ bit.listserv.l-hcap		wtm@bunker.shel.isc-br.com . bit.listserv.libres		librk329@KentVMS.Kent.edu- bit.listserv.new-list		NU021172@VM1.NoDak.EDUn4 bit.listserv.pacs-l		LIBPACS%UHUPVM1@CUNYVM.CUNY.EDU$ bit.listserv.valert-l		krvw@cert.org- biz.dec.decnews			decnews@mr4dec.enet.dec.com)) biz.sco.announce		scoannmod@xenitec.on.cae! biz.sco.binaries		sl@wimsey.bc.ca , biz.sco.sources			kd1hz@anomaly.sbs.risc.net$ biz.zeos.announce		kgermann@zeos.com can.canet.d			canet-d@canet.ca( can.uucp.maps			pathadmin@cs.toronto.edu< comp.protocols.iso.x400.gateway	ifip-gtwy-usenet@ics.uci.edu% comp.security.announce		cert@cert.orge! ddn.mgt-bulletin		nic@nic.ddn.milt  ddn.newsletter			nic@nic.ddn.mil/ de.admin.lists			de-admin-lists@hactar.hanse.deb) de.admin.submaps		maps@flatlin.ka.sub.org 0 de.comp.sources.amiga		agnus@amylnd.stgt.sub.org3 de.comp.sources.misc		sources@watzman.quest.sub.orgk+ de.comp.sources.os9		fkk@stasys.sta.sub.orge4 de.comp.sources.st		sources-st@watzman.quest.sub.org: de.comp.sources.unix		de-comp-sources-unix@germany.sun.com  de.mag.chalisti			ccc@sol.ccc.de) de.newusers			newusers@jattmp.nbg.sub.org  de.org.dfn			org-dfn@dfn.de(" de.org.eunet			news@germany.eu.net# de.org.sub			vorstand@smurf.sub.org * de.sci.ki			hein@damon.irf.uni-dortmund.de0 de.sci.ki.mod.ki		hein@damon.irf.uni-dortmund.de% fj.announce			fj-announce@junet.ad.jpU% fj.binaries			fj-binaries@junet.ad.jpR2 fj.binaries.x68000		fj-binaries-x68000@junet.ad.jp+ fj.guide.admin			fj-guide-admin@junet.ad.jpo. fj.guide.general		fj-guide-general@junet.ad.jp0 fj.guide.newusers		fj-guide-newusers@junet.ad.jp fj.map				fj-map@junet.ad.jp' gnu.announce			info-gnu@prep.ai.mit.edut' gnu.bash.bug			bug-bash@prep.ai.mit.edud2 gnu.emacs.announce		info-gnu-emacs@prep.ai.mit.edu- gnu.emacs.bug			bug-gnu-emacs@prep.ai.mit.eduu* gnu.g++.announce		info-g++@prep.ai.mit.edu% gnu.g++.bug			bug-g++@prep.ai.mit.edue- gnu.g++.lib.bug			bug-lib-g++@prep.ai.mit.edul* gnu.gcc.announce		info-gcc@prep.ai.mit.edu% gnu.gcc.bug			bug-gcc@prep.ai.mit.eduh% gnu.gdb.bug			bug-gdb@prep.ai.mit.edu.4 gnu.ghostscript.bug		bug-ghostscript@prep.ai.mit.edu) gnu.groff.bug			bug-groff@prep.ai.mit.edui4 gnu.smalltalk.bug		bug-gnu-smalltalk@prep.ai.mit.edu- gnu.utils.bug			bug-gnu-utils@prep.ai.mit.educ) houston.weather			weather-monitor@tmc.edug ieee.tcos			tcos@cse.ucsc.edu	' info.academic.freedom		caf-talk@eff.org@$ info.admin			usenet@ux1.cso.uiuc.edu" info.bind			bind@arpa.berkeley.edu info.brl.cad			cad@brl.mil. info.bytecounters		bytecounters@venera.isi.edu( info.cmu.tek.tcp		cmu-tek-tcp@cs.cmu.edu/ info.convex			info-convex@pemrac.space.swri.educ# info.firearms			firearms@cs.cmu.edup4 info.firearms.politics		firearms-politics@cs.cmu.edu/ info.gated			gated-people@devvax.tn.cornell.edu  info.ietf			ietf@venera.isi.educ) info.ietf.hosts			ietf-hosts@nnsc.nsf.net., info.ietf.isoc			isoc-interest@relay.sgi.com info.ietf.njm			njm@merit.eduy- info.ietf.smtp			ietf-smtp@dimacs.rutgers.educ info.isode			isode@nic.ddn.mil) info.jethro.tull		jtull@remus.rutgers.edur! info.labmgr			labmgr@ukcc.uky.edu@  info.mach			info-mach@cs.cmu.edu( info.mh.workers			mh-workers@ics.uci.edu info.nets			info-nets@think.com % info.nsf.grants			grants@note.nsf.govc' info.nsfnet.cert		nsfnet-cert@merit.eduu) info.nysersnmp			nysersnmp@nisc.nyser.netn info.osf			roma@uiuc.edu info.pem.dev			pem-dev@tis.com# info.ph				info-ph@uxc.cso.uiuc.edut" info.rfc			rfc-request@nic.ddn.mil info.snmp			snmp@nisc.nyser.netc( info.sun.managers		sun-managers@rice.edu' info.sun.nets			sun-nets@umiacs.umd.edup& info.theorynt			theorynt@vm1.nodak.edu5 info.unix.sw			unix-sw-request@wsmr-simtel20.army.milt mi.map				uucpmap@rel.mi.org- opinions.supreme-court		opinions@uunet.uu.netsA relcom.infomarket.quote		relcom-infomarket-quote@news.ussr.eu.netm? relcom.infomarket.talk		relcom-infomarket-talk@news.ussr.eu.netr. relcom.jusinf			relcom-jusinf@news.ussr.eu.net7 relcom.postmasters		relcom-postmasters@news.ussr.eu.netu. relcom.renews			relcom-renews@news.ussr.eu.net* resif.oracle			oracle@grasp1.univ-lyon1.fr, sfnet.atk.flpf.tiedotukset	flpf@nic.funet.fi$ sfnet.csc.tiedotukset		netmgr@csc.fi* sfnet.funet.tiedotukset		toimitus@funet.fi6 sfnet.fuug.tiedotukset		sfnet-fuug-tiedotukset@fuug.fi3 sfnet.harrastus.astronomia	pvtmakela@cc.helsinki.fix$ sfnet.harrastus.mensa		jau@cs.tut.fi0 sfnet.lists.sunflash		flash@sunvice.East.Sun.COM1 sfnet.opiskelu.ymp.kurssit	hoffren@cc.Helsinki.FIo> sfnet.tiede.tilastotiede.jatkokoulutus	til_tied@cc.helsinki.fi- sura.announce			sura-announce@darwin.sura.neto1 sura.noc.status			sura-noc-status@darwin.sura.nett- sura.security			sura-security@darwin.sura.neto0 tamu.religion.christian		shetler@eemips.tamu.edu0 tx-thenet-managers		themgr-moderator@nic.the.net! tx.maps				texas-uucpmaps@tmc.edui+ uiuc.org.men			uiuc-men-ml@ux1.cso.uiuc.edus6 uunet.alternet			asp@uunet.uu.net,postman@uunet.uu.net% uunet.announce			postman@uunet.uu.neto% uunet.products			postman@uunet.uu.net	# uunet.status			postman@uunet.uu.net.! uunet.tech			postman@uunet.uu.net., vmsnet.announce			vmsnet-announce@mccall.com< vmsnet.announce.newusers	vmsnet-announce-newusers@mccall.com, vmsnet.sources			vmsnet-sources@mvb.saic.com $eod d