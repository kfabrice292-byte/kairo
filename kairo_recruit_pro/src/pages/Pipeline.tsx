import { useEffect, useState } from "react";
import { useSearchParams, useNavigate } from "react-router-dom";
import { DragDropContext, Droppable, Draggable } from "@hello-pangea/dnd";
import type { DropResult } from "@hello-pangea/dnd";
import { usePipelineStore } from "../store/usePipelineStore";
import { CandidateCard } from "../components/CandidateCard";
import { CandidateProfileModal } from "../components/CandidateProfileModal";
import { PipelineActionModal } from "../components/PipelineActionModal";
import { ArrowLeft } from "lucide-react";

import type { PipelineItem } from "../store/usePipelineStore";

export function Pipeline() {
  const [searchParams] = useSearchParams();
  const jobId = searchParams.get('jobId');
  const navigate = useNavigate();
  
  const { data, setActiveJob, moveItem } = usePipelineStore();
  const [selectedItem, setSelectedItem] = useState<PipelineItem | null>(null);
  const [actionCandidate, setActionCandidate] = useState<{ item: PipelineItem, action: 'interview' | 'reject' | 'hire' } | null>(null);

  useEffect(() => {
    if (jobId) {
      setActiveJob(jobId);
    }
  }, [jobId, setActiveJob]);

  if (!jobId) {
    return <div>Aucune offre sélectionnée.</div>;
  }

  const onDragEnd = (result: DropResult) => {
    const { destination, source, draggableId } = result;

    if (!destination) return;
    if (
      destination.droppableId === source.droppableId &&
      destination.index === source.index
    ) {
      return;
    }

    moveItem(
      draggableId,
      source.droppableId,
      destination.droppableId,
      source.index,
      destination.index
    );

    const item = data.items[draggableId];
    if (destination.droppableId === 'interview') {
      setActionCandidate({ item, action: 'interview' });
    } else if (destination.droppableId === 'rejected') {
      setActionCandidate({ item, action: 'reject' });
    } else if (destination.droppableId === 'hired') {
      setActionCandidate({ item, action: 'hire' });
    }
  };

  return (
    <div className="h-full flex flex-col overflow-hidden">
      <div className="mb-6 flex items-center">
        <button 
          onClick={() => navigate('/jobs')}
          className="mr-4 p-2 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-lg text-slate-500 hover:text-primary transition-colors"
        >
          <ArrowLeft className="w-5 h-5" />
        </button>
        <div>
          <h1 className="text-2xl font-bold text-slate-900 dark:text-white">Pipeline de recrutement</h1>
          <p className="text-slate-500 dark:text-slate-400 text-sm">Faites glisser les candidats pour les faire avancer dans le processus.</p>
        </div>
      </div>

      <div className="flex-1 overflow-x-auto overflow-y-hidden">
        <DragDropContext onDragEnd={onDragEnd}>
          <div className="flex h-full space-x-4 pb-4">
            {data.columnOrder.map((columnId) => {
              const column = data.columns[columnId];
              const items = column.itemIds.map(itemId => data.items[itemId]);

              return (
                <div key={column.id} className="flex flex-col w-80 flex-shrink-0 bg-slate-100 dark:bg-slate-900/50 rounded-xl border border-slate-200 dark:border-slate-800 overflow-hidden">
                  <div className="p-4 border-b border-slate-200 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-950/50 flex justify-between items-center">
                    <h3 className="font-bold text-slate-700 dark:text-slate-300">{column.title}</h3>
                    <span className="bg-white dark:bg-slate-800 text-slate-500 text-xs font-bold px-2 py-1 rounded-full shadow-sm">
                      {items.length}
                    </span>
                  </div>
                  
                  <Droppable droppableId={column.id}>
                    {(provided, snapshot) => (
                      <div
                        {...provided.droppableProps}
                        ref={provided.innerRef}
                        className={`flex-1 overflow-y-auto p-3 space-y-3 transition-colors ${snapshot.isDraggingOver ? 'bg-primary/5' : ''}`}
                      >
                        {items.map((item, index) => (
                          <Draggable key={item.id} draggableId={item.id} index={index}>
                            {(provided, snapshot) => (
                              <div
                                ref={provided.innerRef}
                                {...provided.draggableProps}
                                {...provided.dragHandleProps}
                                className={snapshot.isDragging ? 'opacity-80 rotate-2 scale-105' : ''}
                                style={{ ...provided.draggableProps.style }}
                              >
                                <CandidateCard 
                                  talent={item.candidate} 
                                  matchScore={item.matchScore}
                                  onClick={() => setSelectedItem(item)} 
                                />
                              </div>
                            )}
                          </Draggable>
                        ))}
                        {provided.placeholder}
                      </div>
                    )}
                  </Droppable>
                </div>
              );
            })}
          </div>
        </DragDropContext>
      </div>

      {selectedItem && (
        <CandidateProfileModal 
          talent={selectedItem.candidate} 
          application={selectedItem}
          onClose={() => setSelectedItem(null)} 
        />
      )}

      {actionCandidate && (
        <PipelineActionModal
          action={actionCandidate.action}
          item={actionCandidate.item}
          onClose={() => setActionCandidate(null)}
        />
      )}
    </div>
  );
}
