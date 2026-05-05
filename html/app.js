let selectedOfferId = null;
let currentOffers = [];
let adrAnswers = {};

const app = document.getElementById('app');
const dispatcher = document.getElementById('dispatcher');
const documentView = document.getElementById('document-view');
const adrExam = document.getElementById('adr-exam');
const policeView = document.getElementById('police-view');

function post(name, data = {}) {
    return fetch(`https://${GetParentResourceName()}/${name}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8'
        },
        body: JSON.stringify(data)
    });
}

function showApp() {
    app.classList.remove('hidden');
}

function hideAll() {
    dispatcher.classList.add('hidden');
    documentView.classList.add('hidden');
    adrExam.classList.add('hidden');
    policeView.classList.add('hidden');
}

function closeUi() {
    hideAll();
    app.classList.add('hidden');
    post('close');
}

function refreshOffers() {
    post('refreshOffers');
}

function formatMoney(value) {
    return `$${Number(value || 0).toLocaleString('de-DE')}`;
}

function setText(id, value) {
    const el = window.document.getElementById(id);
    if (el) el.textContent = value;
}

function renderDispatcher(data) {
    showApp();
    hideAll();

    dispatcher.classList.remove('hidden');

    selectedOfferId = null;
currentOffers = data.offers || [];

setText('dispatcher-title', data.title || 'Dispatcher Panel');
setText('dispatcher-subtitle', data.subtitle || 'DK Logistics Center');

renderProfile(data.profile);
renderUnlocks(data.unlocks || []);

if (data.activeRun) {
    renderActiveRun(data.activeRun);
    return;
}

renderOffers(currentOffers);

const details = window.document.getElementById('offer-details');
details.className = 'details-box empty';
details.textContent = 'Wähle einen Auftrag aus.';

const acceptButton = window.document.getElementById('accept-button');
acceptButton.textContent = 'Auftrag annehmen';
acceptButton.disabled = true;
acceptButton.onclick = acceptSelectedOffer;
}

function renderProfile(profile) {
    if (!profile) return;

    setText('profile-level', profile.level || 1);
    setText('profile-title', profile.levelLabel || 'Fahrer');

    const currentXp = profile.xp || 0;
    const nextXp = profile.nextLevelXp || currentXp;
    setText('profile-xp', `${currentXp.toLocaleString('de-DE')} / ${nextXp.toLocaleString('de-DE')}`);

    const fill = window.document.getElementById('profile-xp-fill');
    fill.style.width = `${profile.progress || 0}%`;

    const licenses = window.document.getElementById('license-list');
    licenses.innerHTML = '';

    const licenseData = [
        { label: 'ADR', active: profile.licenses && profile.licenses.adr },
        { label: 'Schwerlast', active: profile.licenses && profile.licenses.heavy },
        { label: 'Kühlkette', active: profile.licenses && profile.licenses.coolchain }
    ];

    licenseData.forEach(item => {
        const div = window.document.createElement('div');
        div.className = item.active ? 'tag' : 'tag locked';
        div.textContent = item.active ? item.label : `${item.label}: fehlt`;
        licenses.appendChild(div);
    });

    setText('stat-completed', profile.completedJobs || 0);
    setText('stat-failed', profile.failedJobs || 0);
    setText('stat-adr', profile.hazmatCompleted || 0);
}

function renderOffers(offers) {
    const list = window.document.getElementById('offer-list');
    list.innerHTML = '';

    if (!offers || offers.length === 0) {
        const empty = window.document.createElement('div');
        empty.className = 'details-box empty';
        empty.textContent = 'Keine passenden Aufträge verfügbar.';
        list.appendChild(empty);
        return;
    }

    offers.forEach(offer => {
        const div = window.document.createElement('div');
        div.className = 'offer';
        div.dataset.offerId = offer.id;

        div.innerHTML = `
            <h3>${escapeHtml(offer.label)}</h3>
            <div class="offer-meta">
                <span>${escapeHtml(offer.category)}</span>
                <span>${escapeHtml(offer.pickupLabel || offer.pickupId)} → ${escapeHtml(offer.receiverLabel || offer.receiverId)}</span>
                <span>${escapeHtml(offer.vehicle)}${offer.trailer ? ' + ' + escapeHtml(offer.trailer) : ''}</span>
                <span>${formatMoney(offer.payout?.min)} - ${formatMoney(offer.payout?.max)}</span>
                ${offer.requiresAdr ? '<span>ADR</span>' : ''}
                ${offer.requiresSeal ? '<span>Plombe</span>' : ''}
            </div>
        `;

        div.onclick = () => selectOffer(offer.id);

        list.appendChild(div);
    });
}

function renderActiveRun(run) {
    const list = window.document.getElementById('offer-list');
    const details = window.document.getElementById('offer-details');
    const actionButton = window.document.getElementById('accept-button');

    list.innerHTML = '';

    const activeBox = window.document.createElement('div');
    activeBox.className = 'offer selected';

    activeBox.innerHTML = `
        <h3>Aktueller Auftrag</h3>
        <div class="offer-meta">
            <span>${escapeHtml(run.category || '-')}</span>
            <span>${escapeHtml(run.pickupLabel || run.originLabel || '-')} → ${escapeHtml(run.receiverLabel || run.destinationLabel || '-')}</span>
            <span>${escapeHtml(run.vehicle || '-')}${run.trailer ? ' + ' + escapeHtml(run.trailer) : ''}</span>
            <span>Status: ${escapeHtml(run.state || '-')}</span>
        </div>
    `;

    list.appendChild(activeBox);

    details.className = 'details-box';

    details.innerHTML = `
        <div class="detail-grid">
            <div class="detail-item">
                <span>Auftrag</span>
                <strong>${escapeHtml(run.label || run.templateId || '-')}</strong>
            </div>

            <div class="detail-item">
                <span>Status</span>
                <strong>${escapeHtml(formatRunState(run.state))}</strong>
            </div>

            <div class="detail-item">
                <span>Fracht</span>
                <strong>${escapeHtml(run.cargoAmount)}x ${escapeHtml(run.cargoLabel || '-')}</strong>
            </div>

            <div class="detail-item">
                <span>Abholung</span>
                <strong>${escapeHtml(run.pickupLabel || run.originLabel || '-')}</strong>
            </div>

            <div class="detail-item">
                <span>Empfänger</span>
                <strong>${escapeHtml(run.receiverLabel || run.destinationLabel || '-')}</strong>
            </div>

            <div class="detail-item">
                <span>LKW</span>
                <strong>${escapeHtml(run.vehicle || '-')} / ${escapeHtml(run.truckPlate || '-')}</strong>
            </div>

            <div class="detail-item">
                <span>Trailer</span>
                <strong>${escapeHtml(run.trailer || 'Kein Trailer')} / ${escapeHtml(run.trailerPlate || '-')}</strong>
            </div>

            <div class="detail-item">
                <span>Plombe</span>
                <strong>${escapeHtml(run.sealNumber || 'Keine')}</strong>
            </div>

            <div class="detail-item">
                <span>Papiere</span>
                <strong>${run.documentsCollected ? 'Abgeholt' : 'Noch nicht abgeholt'}</strong>
            </div>

            <div class="detail-item">
                <span>Geplante Auszahlung</span>
                <strong>${formatMoney(run.basePayout || 0)}</strong>
            </div>

            <div class="detail-item">
                <span>Geplante XP</span>
                <strong>${Number(run.baseXp || 0).toLocaleString('de-DE')}</strong>
            </div>

            <div class="detail-item danger">
                <span>Abbruch-Strafe</span>
                <strong>-${Number(run.cancelXpPenalty || 0).toLocaleString('de-DE')} XP</strong>
            </div>
        </div>

        <div class="details-warning">
            Wenn du diesen Auftrag abbrichst, werden dir die Mindest-XP dieses Auftrags abgezogen.
        </div>
    `;

    actionButton.textContent = `Auftrag abbrechen (-${Number(run.cancelXpPenalty || 0).toLocaleString('de-DE')} XP)`;
    actionButton.disabled = false;
    actionButton.onclick = cancelActiveRunFromDispatcher;
}

function selectOffer(offerId) {
    selectedOfferId = offerId;

    window.document.querySelectorAll('.offer').forEach(el => {
        el.classList.toggle('selected', el.dataset.offerId === offerId);
    });

    const offer = currentOffers.find(item => item.id === offerId);
    renderOfferDetails(offer);

    window.document.getElementById('accept-button').disabled = !offer;
}

function renderOfferDetails(offer) {
    const details = window.document.getElementById('offer-details');

    if (!offer) {
        details.className = 'details-box empty';
        details.textContent = 'Wähle einen Auftrag aus.';
        return;
    }

    details.className = 'details-box';

    const licenses = offer.requiredLicenses && offer.requiredLicenses.length > 0
        ? offer.requiredLicenses.join(', ')
        : 'Keine';

    const cargoAmountText = typeof offer.cargoAmount === 'object'
        ? `${offer.cargoAmount.min || 0} - ${offer.cargoAmount.max || 0}`
        : `${offer.cargoAmount || 0}`;

    details.innerHTML = `
        <div class="detail-grid">
            <div class="detail-item">
                <span>Fracht</span>
                <strong>${escapeHtml(cargoAmountText)}x ${escapeHtml(offer.cargoLabel)}</strong>
            </div>
            <div class="detail-item">
                <span>Kategorie</span>
                <strong>${escapeHtml(offer.category)}</strong>
            </div>
            <div class="detail-item">
                <span>Abholung</span>
                <strong>${escapeHtml(offer.pickupLabel || offer.pickupId)}</strong>
            </div>
            <div class="detail-item">
                <span>Empfänger</span>
                <strong>${escapeHtml(offer.receiverLabel || offer.receiverId)}</strong>
            </div>
            <div class="detail-item">
                <span>Fahrzeug</span>
                <strong>${escapeHtml(offer.vehicle)}</strong>
            </div>
            <div class="detail-item">
                <span>Trailer</span>
                <strong>${escapeHtml(offer.trailer || 'Kein Trailer')}</strong>
            </div>
            <div class="detail-item">
                <span>Bezahlung</span>
                <strong>${formatMoney(offer.payout?.min)} - ${formatMoney(offer.payout?.max)}</strong>
            </div>
            <div class="detail-item">
                <span>XP</span>
                <strong>${offer.xp?.min || 0} - ${offer.xp?.max || 0}</strong>
            </div>
            <div class="detail-item">
                <span>Plombe</span>
                <strong>${offer.requiresSeal ? 'Ja' : 'Nein'}</strong>
            </div>
            <div class="detail-item">
                <span>Berechtigungen</span>
                <strong>${escapeHtml(licenses)}</strong>
            </div>
        </div>
    `;
}

function acceptSelectedOffer() {
    if (!selectedOfferId) return;

    post('acceptOffer', {
        offerId: selectedOfferId
    });
}

function renderUnlocks(unlocks) {
    const list = window.document.getElementById('unlock-list');
    list.innerHTML = '';

    unlocks.forEach(unlock => {
        const div = window.document.createElement('div');
        div.className = unlock.unlocked ? 'unlock unlocked' : 'unlock locked';

        let status = unlock.unlocked
            ? 'Freigeschaltet'
            : `Benötigt Level ${unlock.requiredLevel}`;

        if (!unlock.unlocked && unlock.examRequired) {
            status += ' + Prüfung';
        }

        if (!unlock.unlocked && unlock.licenseRequired) {
            status += ' + Lizenz';
        }

        div.innerHTML = `
            <strong>${escapeHtml(unlock.label)}</strong>
            <span>${escapeHtml(status)}</span>
        `;

        list.appendChild(div);
    });
}

function cancelActiveRunFromDispatcher() {
    post('cancelActiveRun').then(() => {
        closeUi();
    });
}

function formatRunState(state) {
    const states = {
        VEHICLE_ASSIGNED: 'Fahrzeug zugewiesen',
        KEYS_ISSUED: 'Schlüssel ausgegeben',
        EN_ROUTE_PICKUP: 'Auf dem Weg zur Abholung',
        AT_PICKUP: 'Am Abholort',
        LOADING_STARTED: 'Beladung läuft',
        LOADED: 'Beladen',
        EN_ROUTE_DELIVERY: 'Auf dem Weg zum Empfänger',
        AT_RECEIVER: 'Beim Empfänger',
        UNLOADING: 'Entladung läuft',
        RETURN_TO_DEPOT: 'Fahrzeugrückgabe offen',
        COMPLETED: 'Abgeschlossen',
        FAILED: 'Fehlgeschlagen',
        CANCELLED: 'Abgebrochen'
    };

    return states[state] || state || '-';
}

function renderDocument(info) {
    console.log('[dk-spedition] renderDocument payload:', info);

    showApp();
    hideAll();

    const view = window.document.getElementById('document-view');
    const title = window.document.getElementById('document-title');
    const content = window.document.getElementById('document-content');

    if (!view || !content) {
        console.error('[dk-spedition] document-view oder document-content fehlt.');
        return;
    }

    view.classList.remove('hidden');

    const documentLabel =
        info.documentLabel ||
        (info.document && info.document.label) ||
        info.documentType ||
        'Dokument';

    if (title) {
        title.textContent = documentLabel;
    }

    try {
        if (info.documentType === 'adr_transport_paper' || info.documentType === 'adr_transport_sheet') {
            renderAdrTransportPaper(info);
            return;
        }

        if (info.documentType === 'hazmat_permit') {
            renderHazmatPermit(info);
            return;
        }

        if (info.documentType === 'delivery_note') {
            renderDeliveryNote(info);
            return;
        }

        if (info.documentType === 'cargo_manifest') {
            renderCargoManifest(info);
            return;
        }

        content.innerHTML = `<pre>${escapeHtml(info.description || JSON.stringify(info, null, 2))}</pre>`;
    } catch (err) {
        console.error('[dk-spedition] Dokument konnte nicht gerendert werden:', err);

        content.innerHTML = `
            <div class="paper">
                <h2>Dokument konnte nicht gerendert werden</h2>
                <pre>${escapeHtml(info.description || JSON.stringify(info, null, 2))}</pre>
            </div>
        `;
    }
}

function escapeHtml(value) {
    return String(value ?? '').replace(/[&<>"']/g, char => ({
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#039;'
    }[char]));
}

function formatDocAmount(amount, unit) {
    const numeric = Number(amount || 0);

    if (Number.isFinite(numeric)) {
        return `${numeric.toLocaleString('de-DE')} ${unit || ''}`.trim();
    }

    return `${amount || '-'} ${unit || ''}`.trim();
}

function getDocParts(info) {
    return {
        doc: info.document || {},
        company: info.companyData || {
            name: info.company || 'Spedition',
            subtitle: info.companySubtitle || ''
        },
        driver: info.driverData || {
            name: info.driver,
            truckPlate: info.truckPlate,
            trailerPlate: info.trailerPlate,
            sealNumber: info.sealNumber
        },
        sender: info.senderData || {},
        loader: info.loaderData || {},
        pickup: info.pickupData || {
            label: info.origin,
            address: ''
        },
        receiver: info.receiverData || {
            label: info.destination,
            address: ''
        },
        cargo: info.cargoData || {
            label: info.cargo,
            amount: info.cargoAmount,
            unit: info.cargoUnit || 'Stk.',
            item: info.cargoItem
        },
        hazard: info.hazardData || {},
        meta: info.meta || {}
    };
}

function renderCargoManifest(info) {
    const content = window.document.getElementById('document-content');
    const { doc, company, driver, sender, pickup, receiver, cargo } = getDocParts(info);

    content.innerHTML = `
        <div class="paper cargo-paper">
            <div class="paper-header">
                <div>
                    <h2>${escapeHtml(company.name || 'Spedition')}</h2>
                    <p>${escapeHtml(company.subtitle || '')}</p>
                </div>
                <div class="paper-meta">
                    <strong>Frachtbrief / Ladungsmanifest</strong><br>
                    Dokument: ${escapeHtml(doc.serial || info.serial || '-')}<br>
                    Auftrag: ${escapeHtml(doc.orderId || info.runId || '-')}<br>
                    Ausgestellt: ${escapeHtml(doc.issuedAt || info.issuedAt || '-')}<br>
                    Gültig bis: ${escapeHtml(doc.validUntil || info.validUntil || '-')}
                </div>
            </div>

            <div class="paper-grid two">
                <div class="paper-box">
                    <h3>Absender</h3>
                    <strong>${escapeHtml(sender.name || company.name || '-')}</strong><br>
                    ${escapeHtml(sender.street || '')}<br>
                    ${escapeHtml(sender.zipCity || '')}<br>
                    ${escapeHtml(sender.country || '')}
                </div>

                <div class="paper-box">
                    <h3>Empfänger</h3>
                    <strong>${escapeHtml(receiver.label || '-')}</strong><br>
                    ${escapeHtml(receiver.address || '')}
                </div>

                <div class="paper-box">
                    <h3>Verladeort</h3>
                    <strong>${escapeHtml(pickup.label || '-')}</strong><br>
                    ${escapeHtml(pickup.address || '')}
                </div>

                <div class="paper-box">
                    <h3>Transport</h3>
                    Fahrer: ${escapeHtml(driver.name || '-')}<br>
                    LKW: ${escapeHtml(driver.truckPlate || '-')}<br>
                    Trailer: ${escapeHtml(driver.trailerPlate || '-')}<br>
                    Plombe: ${escapeHtml(driver.sealNumber || '-')}
                </div>
            </div>

            <table class="paper-table">
                <thead>
                    <tr>
                        <th>Pos.</th>
                        <th>Artikel / Bezeichnung</th>
                        <th>Item-ID</th>
                        <th>Menge</th>
                        <th>Einheit</th>
                        <th>Kategorie</th>
                        <th>Bemerkung</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td>1</td>
                        <td>${escapeHtml(cargo.label || '-')}</td>
                        <td>${escapeHtml(cargo.item || '-')}</td>
                        <td>${escapeHtml(Number(cargo.amount || 0).toLocaleString('de-DE'))}</td>
                        <td>${escapeHtml(cargo.unit || 'Stk.')}</td>
                        <td>${escapeHtml(cargo.category || '-')}</td>
                        <td>${cargo.requiresSeal ? 'Plombe erforderlich' : 'Keine Plombe erforderlich'}</td>
                    </tr>
                </tbody>
            </table>

            <div class="paper-notes">
                <strong>Vermerke:</strong><br>
                [ ] Ware vollständig verladen<br>
                [ ] Papiere übergeben<br>
                [ ] Sichtprüfung ohne Beanstandung
            </div>

            <div class="signature-grid">
                <div>
                    <div class="signature-line"></div>
                    Fahrer
                </div>
                <div>
                    <div class="signature-line"></div>
                    Verlader
                </div>
            </div>
        </div>
    `;
}

function renderDeliveryNote(info) {
    const content = window.document.getElementById('document-content');
    const { doc, company, driver, pickup, receiver, cargo } = getDocParts(info);

    content.innerHTML = `
        <div class="paper delivery-paper">
            <div class="paper-header">
                <div>
                    <h2>${escapeHtml(company.name || 'Spedition')}</h2>
                    <p>${escapeHtml(company.subtitle || '')}</p>
                </div>
                <div class="paper-meta">
                    <strong>Lieferschein / Empfangsbestätigung</strong><br>
                    Beleg: ${escapeHtml(doc.serial || info.serial || '-')}<br>
                    Auftrag: ${escapeHtml(doc.orderId || info.runId || '-')}<br>
                    Datum: ${escapeHtml(doc.issuedAt || info.issuedAt || '-')}
                </div>
            </div>

            <div class="paper-grid two">
                <div class="paper-box">
                    <h3>Von</h3>
                    <strong>${escapeHtml(pickup.label || '-')}</strong><br>
                    ${escapeHtml(pickup.address || '')}
                </div>

                <div class="paper-box">
                    <h3>An</h3>
                    <strong>${escapeHtml(receiver.label || '-')}</strong><br>
                    ${escapeHtml(receiver.address || '')}
                </div>

                <div class="paper-box">
                    <h3>Fahrer / Fahrzeug</h3>
                    Fahrer: ${escapeHtml(driver.name || '-')}<br>
                    LKW: ${escapeHtml(driver.truckPlate || '-')}<br>
                    Trailer: ${escapeHtml(driver.trailerPlate || '-')}
                </div>

                <div class="paper-box">
                    <h3>Dokumentenstatus</h3>
                    Originaldokument<br>
                    Gültig bis: ${escapeHtml(doc.validUntil || info.validUntil || '-')}<br>
                    Plombe: ${escapeHtml(driver.sealNumber || '-')}
                </div>
            </div>

            <table class="paper-table">
                <thead>
                    <tr>
                        <th>Pos.</th>
                        <th>Bezeichnung</th>
                        <th>Menge Soll</th>
                        <th>Menge Ist</th>
                        <th>Einheit</th>
                        <th>Zustand</th>
                        <th>Bemerkung</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td>1</td>
                        <td>${escapeHtml(cargo.label || '-')}</td>
                        <td>${escapeHtml(Number(cargo.amount || 0).toLocaleString('de-DE'))}</td>
                        <td>__________</td>
                        <td>${escapeHtml(cargo.unit || 'Stk.')}</td>
                        <td>__________</td>
                        <td>__________</td>
                    </tr>
                </tbody>
            </table>

            <div class="paper-box">
                <h3>Empfangsvermerk</h3>
                [ ] Ware vollständig erhalten<br>
                [ ] Ware unter Vorbehalt angenommen<br>
                [ ] Transportschaden festgestellt<br><br>
                Bemerkungen:<br>
                <div class="note-lines"></div>
            </div>

            <div class="signature-grid three">
                <div>
                    <div class="signature-line"></div>
                    Empfänger
                </div>
                <div>
                    <div class="signature-line"></div>
                    Fahrer
                </div>
                <div>
                    <div class="signature-line"></div>
                    Datum / Uhrzeit
                </div>
            </div>
        </div>
    `;
}

function renderAdrTransportPaper(info) {
    const content = window.document.getElementById('document-content');
    const { doc, company, driver, sender, loader, receiver, cargo, hazard } = getDocParts(info);

    const amount = formatDocAmount(cargo.amount, cargo.unit);

    content.innerHTML = `
        <div class="paper adr-paper">
            <div class="adr-stripes left"></div>
            <div class="adr-stripes right"></div>

            <h1>Beförderungspapier gem. Kapitel 5.4 ADR</h1>

            <div class="company-text">
                <strong>${escapeHtml(company.name || 'Spedition')}</strong><br>
                <span>${escapeHtml(company.subtitle || '')}</span>
            </div>

            <div class="adr-address-grid">
                <div>
                    <h3>Absender:</h3>
                    <strong>${escapeHtml(sender.name || company.name || '-')}</strong><br>
                    ${escapeHtml(sender.street || '')}<br>
                    ${escapeHtml(sender.zipCity || '')}<br>
                    ${escapeHtml(sender.country || '')}<br>
                    Tel.: ${escapeHtml(sender.phone || '-')}<br>
                    E-Mail: ${escapeHtml(sender.email || '-')}
                </div>

                <div>
                    <h3>Empfänger:</h3>
                    <strong>${escapeHtml(receiver.label || '-')}</strong><br>
                    ${escapeHtml(receiver.address || '')}
                </div>

                <div>
                    <h3>Verlader:</h3>
                    <strong>${escapeHtml(loader.name || '-')}</strong><br>
                    ${escapeHtml(loader.street || '')}<br>
                    ${escapeHtml(loader.zipCity || '')}<br>
                    ${escapeHtml(loader.country || '')}<br>
                    Tel.: ${escapeHtml(loader.phone || '-')}<br>
                    E-Mail: ${escapeHtml(loader.email || '-')}
                </div>
            </div>

            <table class="adr-table">
                <thead>
                    <tr>
                        <th>UN-Nummer</th>
                        <th>Stoffbezeichnung</th>
                        <th>Hauptgefahr</th>
                        <th>Nebengefahr</th>
                        <th>Verp.-gruppe</th>
                        <th>Tunnelcode</th>
                        <th>Menge</th>
                        <th>Anzahl</th>
                        <th>Art</th>
                        <th>Bef.-Kategorie</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td>${escapeHtml(hazard.unNumber || '-')}</td>
                        <td>${escapeHtml(hazard.substanceName || cargo.label || '-')}</td>
                        <td>${escapeHtml(hazard.hazardMain || hazard.adrClass || '-')}</td>
                        <td>${escapeHtml(hazard.hazardSub || '-')}</td>
                        <td>${escapeHtml(hazard.packingGroup || '-')}</td>
                        <td>${escapeHtml(hazard.tunnelCode || '-')}</td>
                        <td>${escapeHtml(amount)}</td>
                        <td>${escapeHtml(hazard.packageCountLabel || '1')}</td>
                        <td>${escapeHtml(hazard.packagingDescription || hazard.packagingType || '-')}</td>
                        <td>${escapeHtml(hazard.transportCategory || '-')}</td>
                    </tr>
                </tbody>
            </table>

            <div class="adr-summary">
                <p>
                    Beförderung <span class="green-tag">ohne</span>
                    Überschreitung der in Unterabschnitt 1.1.3.6 festgesetzten Freigrenzen
                </p>

                <p>
                    Ladung gem. Unterabschnitt 7.5.7 ADR ordnungsgemäß verstaut und gesichert.
                </p>
            </div>

            <div class="doc-meta-grid">
                <div><strong>Dokument:</strong> ${escapeHtml(doc.serial || info.serial || '-')}</div>
                <div><strong>Auftrag:</strong> ${escapeHtml(doc.orderId || info.runId || '-')}</div>
                <div><strong>Ausgestellt:</strong> ${escapeHtml(doc.issuedAt || info.issuedAt || '-')}</div>
                <div><strong>Gültig bis:</strong> ${escapeHtml(doc.validUntil || info.validUntil || '-')}</div>
            </div>

            <div class="signature-box">
                <h3>Oben genanntes ausgeführt, zur Kenntnis und in Empfang genommen:</h3>

                <div class="signature-grid three">
                    <div>
                        <div class="signature-line"></div>
                        Datum
                    </div>

                    <div>
                        <div class="signature-line"></div>
                        Fahrername + Unterschrift<br>
                        LKW: ${escapeHtml(driver.truckPlate || '-')}<br>
                        Trailer: ${escapeHtml(driver.trailerPlate || '-')}
                    </div>

                    <div>
                        <div class="signature-line"></div>
                        Verladername + Unterschrift
                    </div>
                </div>
            </div>
        </div>
    `;
}

function renderHazmatPermit(info) {
    const content = window.document.getElementById('document-content');
    const { doc, company, driver, sender, receiver, cargo, hazard } = getDocParts(info);

    const amount = formatDocAmount(cargo.amount, cargo.unit);

    content.innerHTML = `
        <div class="paper permit-paper">
            <div class="permit-header">
                <div>
                    <h2>${escapeHtml(company.name || 'Spedition')}</h2>
                    <p>${escapeHtml(company.subtitle || '')}</p>
                </div>
                <div>
                    <h1>Gefahrgut-Transportgenehmigung</h1>
                    <p>Mitführdokument für ADR-Sonderfahrt</p>
                </div>
            </div>

            <div class="paper-grid two">
                <div class="paper-box">
                    <h3>Genehmigung</h3>
                    Genehmigungsnummer: <strong>${escapeHtml(doc.serial || info.serial || '-')}</strong><br>
                    Auftrag-ID: ${escapeHtml(doc.orderId || info.runId || '-')}<br>
                    Ausgestellt: ${escapeHtml(doc.issuedAt || info.issuedAt || '-')}<br>
                    Gültig bis: ${escapeHtml(doc.validUntil || info.validUntil || '-')}
                </div>

                <div class="paper-box">
                    <h3>Fahrer / Fahrzeug</h3>
                    Fahrer: ${escapeHtml(driver.name || '-')}<br>
                    ADR-Berechtigung: geprüft<br>
                    LKW: ${escapeHtml(driver.truckPlate || '-')}<br>
                    Trailer: ${escapeHtml(driver.trailerPlate || '-')}<br>
                    Plombe: ${escapeHtml(driver.sealNumber || '-')}
                </div>

                <div class="paper-box">
                    <h3>Absender</h3>
                    <strong>${escapeHtml(sender.name || company.name || '-')}</strong><br>
                    ${escapeHtml(sender.street || '')}<br>
                    ${escapeHtml(sender.zipCity || '')}<br>
                    ${escapeHtml(sender.country || '')}
                </div>

                <div class="paper-box">
                    <h3>Empfänger</h3>
                    <strong>${escapeHtml(receiver.label || '-')}</strong><br>
                    ${escapeHtml(receiver.address || '')}
                </div>
            </div>

            <table class="paper-table">
                <thead>
                    <tr>
                        <th>Stoffbezeichnung</th>
                        <th>UN-Nummer</th>
                        <th>ADR-Klasse</th>
                        <th>Verp.-Gruppe</th>
                        <th>Tunnelcode</th>
                        <th>Menge</th>
                        <th>Transportart</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td>${escapeHtml(hazard.substanceName || cargo.label || '-')}</td>
                        <td>${escapeHtml(hazard.unNumber || '-')}</td>
                        <td>${escapeHtml(hazard.adrClass || '-')}</td>
                        <td>${escapeHtml(hazard.packingGroup || '-')}</td>
                        <td>${escapeHtml(hazard.tunnelCode || '-')}</td>
                        <td>${escapeHtml(amount)}</td>
                        <td>${escapeHtml(hazard.packagingDescription || hazard.packagingType || '-')}</td>
                    </tr>
                </tbody>
            </table>

            <div class="warning-box">
                <h3>Notfallhinweise</h3>
                ${escapeHtml(hazard.emergencyNote || 'Keine besonderen Hinweise hinterlegt.')}<br><br>
                Im Notfall Einsatzkräfte informieren und UN-Nummer, Stoffbezeichnung sowie Menge angeben.
            </div>

            <div class="paper-box">
                <h3>Prüfbestätigung vor Abfahrt</h3>
                [ ] Fahrzeug geprüft<br>
                [ ] Ladung gesichert<br>
                [ ] Papiere vollständig<br>
                [ ] Warnausrüstung vorhanden
            </div>

            <div class="signature-grid three">
                <div>
                    <div class="signature-line"></div>
                    Freigabe / Ausbilder
                </div>
                <div>
                    <div class="signature-line"></div>
                    Fahrer
                </div>
                <div>
                    <div class="signature-line"></div>
                    Verlader
                </div>
            </div>
        </div>
    `;
}

function renderAdrExam(data) {
    showApp();
    hideAll();

    adrExam.classList.remove('hidden');

    adrAnswers = {};

    setText('adr-meta', `Gebühr: ${formatMoney(data.fee)} | Bestehen ab ${data.passPercent}%`);

    const list = window.document.getElementById('adr-question-list');
    list.innerHTML = '';

    (data.questions || []).forEach(question => {
        const box = window.document.createElement('div');
        box.className = 'exam-question';

        let html = `<h3>${question.index}. ${escapeHtml(question.question)}</h3>`;

        question.answers.forEach((answer, idx) => {
            const answerIndex = idx + 1;

            html += `
                <label class="exam-answer">
                    <input type="radio" name="question_${question.index}" value="${answerIndex}" />
                    ${escapeHtml(answer)}
                </label>
            `;
        });

        box.innerHTML = html;

        box.querySelectorAll('input').forEach(input => {
            input.onchange = () => {
                adrAnswers[question.index] = Number(input.value);
            };
        });

        list.appendChild(box);
    });
}

function submitAdrExam() {
    const normalizedAnswers = {};

    Object.keys(adrAnswers).forEach(key => {
        normalizedAnswers[String(key)] = Number(adrAnswers[key]);
    });

    post('submitAdrExam', {
        answers: normalizedAnswers
    });
}

function renderAdrResult(data) {
    const list = window.document.getElementById('adr-question-list');

    list.innerHTML = `
        <div class="exam-question">
            <h3>${data.passed ? 'Bestanden' : 'Nicht bestanden'}</h3>
            <p>Ergebnis: ${data.percent}%</p>
            <p>Richtig: ${data.correct} / ${data.total}</p>
        </div>
    `;
}

function renderPoliceResult(data) {
    showApp();
    hideAll();

    policeView.classList.remove('hidden');

    const content = window.document.getElementById('police-content');

    content.textContent = JSON.stringify(data, null, 2);
}

window.addEventListener('message', event => {
    const message = event.data || {};

    if (message.action === 'openDispatcher') {
        renderDispatcher(message.data || {});
    }

    if (message.action === 'updateDispatcher') {
        renderDispatcher(message.data || {});
    }

    if (message.action === 'close') {
        closeUi();
    }

    if (message.action === 'showDocument') {
        renderDocument(message.data || {});
    }

    if (message.action === 'openAdrExam') {
        renderAdrExam(message.data || {});
    }

    if (message.action === 'adrExamResult') {
        renderAdrResult(message.data || {});
    }

    if (message.action === 'showPoliceDocumentResult') {
        renderPoliceResult(message.data || {});
    }

    if (message.action === 'showPoliceRunResult') {
        renderPoliceResult(message.data || {});
    }

    if (message.action === 'runCompleted') {
        // Optional später: Abschlussfenster anzeigen.
    }
});

window.document.addEventListener('keydown', event => {
    if (event.key === 'Escape') {
        closeUi();
    }
});